require "open3"
require "timeout"

class SistgerImport
  # Where to connect. Each setting comes from its SISTGER_DB_* environment
  # variable when set, otherwise from the Windows registry key the legacy
  # SISTGER client uses (readable from WSL through reg.exe), so the import
  # reads whichever base SISTGER is pointed at. In production (Linux, no
  # reg.exe) only the environment variables apply.
  #
  # The registry names a named instance (mynt\sqlexpress01), which needs the
  # SQL Browser to find its port, and WSL can't reach it. So the instance's
  # TCP port is read from SQL Server's own registry keys (PORTA_INSTANCIA),
  # and SISTGER_DB_HOST only says how to reach the machine. SISTGER_DB_PORT
  # still forces a port.
  class Configuracao
    CHAVE_REGISTRO = 'HKCU\SOFTWARE\VB and VBA Program Settings\oServico\BANCO_DE_DADOS'.freeze
    CHAVE_SQL_SERVER = 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server'.freeze
    REG_EXE = ["reg.exe", "/mnt/c/Windows/system32/reg.exe"].freeze

    attr_reader :host, :instancia, :porta, :banco, :usuario, :senha, :origens

    def self.carregar(env: ENV, registro: nil)
      new(env: env, registro: registro || ler_registro(env))
    end

    # Registry values as {"DATA_SOURCE" => ..., "USER_ID" => ...}, plus
    # "PORTA_INSTANCIA" when the named instance's port was found; {} when the
    # registry isn't reachable or SISTGER_DB_REGISTRO=off.
    def self.ler_registro(env = ENV)
      return {} if env["SISTGER_DB_REGISTRO"] == "off"

      reg = REG_EXE.find { |cmd| cmd.include?("/") ? File.exist?(cmd) : system("command -v #{cmd} >/dev/null 2>&1") }
      return {} unless reg

      valores = consultar(reg, CHAVE_REGISTRO)
      instancia = valores["DATA_SOURCE"].to_s.split("\\", 2)[1]
      if instancia.present? && env["SISTGER_DB_PORT"].blank? && (porta = porta_da_instancia(reg, instancia))
        valores["PORTA_INSTANCIA"] = porta
      end
      valores
    end

    # The TCP port SQL Server listens on for a named instance: the fixed one
    # (TcpPort) or else the dynamic one it picked (TcpDynamicPorts).
    def self.porta_da_instancia(reg, instancia)
      pasta = consultar(reg, "#{CHAVE_SQL_SERVER}\\Instance Names\\SQL")
              .find { |nome, _| nome.casecmp?(instancia) }&.last
      return if pasta.blank?

      ip_all = consultar(reg, "#{CHAVE_SQL_SERVER}\\#{pasta}\\MSSQLServer\\SuperSocketNetLib\\Tcp\\IPAll")
      [ip_all["TcpPort"], ip_all["TcpDynamicPorts"]].map { |p| p.to_s.split(",").first.to_s.strip }.find { |p| p.match?(/\A\d+\z/) }
    end

    # Lines look like "    DATA_SOURCE    REG_SZ    mynt\sqlexpress" (value may be empty).
    def self.consultar(reg, chave)
      saida, status = Timeout.timeout(10) { Open3.capture2e(reg, "query", chave) }
      return {} unless status.success?

      saida.delete("\r").scan(/^\s+(\S+)\s+REG_\w+[ \t]*(.*)$/).to_h
    rescue Timeout::Error, SystemCallError
      {}
    end

    def initialize(env:, registro:)
      @origens = {}
      servidor, instancia = registro["DATA_SOURCE"].to_s.split("\\", 2)

      @host = valor(env, "SISTGER_DB_HOST", servidor.presence, :host)
      @instancia = instancia.presence
      @porta = valor(env, "SISTGER_DB_PORT", registro["PORTA_INSTANCIA"].presence, :porta)&.then { |p| Integer(p) }
      @banco = valor(env, "SISTGER_DB_NAME", registro["INITIAL_CATALOG"].presence, :banco) || "sistger"
      @usuario = valor(env, "SISTGER_DB_USERNAME", registro["USER_ID"].presence, :usuario)
      @senha = if env.key?("SISTGER_DB_PASSWORD")
                 @origens[:senha] = :env
                 env["SISTGER_DB_PASSWORD"].to_s
               else
                 @origens[:senha] = :registro if registro.key?("PASSWORD")
                 registro["PASSWORD"].to_s
               end
    end

    def configurada?
      host.present?
    end

    def usa_registro?
      origens.value?(:registro)
    end

    # With a port the connection goes straight to it; a named instance
    # without one is resolved by the SQL Browser service.
    def servidor
      return "#{host}:#{porta}" if porta

      instancia ? "#{host}\\#{instancia}" : "#{host}:1433"
    end

    def descricao
      notas = [("instância #{instancia}" if instancia && porta), ("registro do Windows" if usa_registro?)].compact
      "#{servidor}, banco #{banco}" + (notas.any? ? " (#{notas.join(', ')})" : "")
    end

    def parametros_conexao
      base = { database: banco, username: usuario, password: senha }
      return base.merge(host: host, port: porta) if porta

      instancia ? base.merge(dataserver: servidor) : base.merge(host: host, port: 1433)
    end

    private

    def valor(env, variavel, do_registro, campo)
      if env[variavel].present?
        @origens[campo] = :env
        env[variavel]
      elsif do_registro
        @origens[campo] = :registro
        do_registro
      end
    end
  end
end
