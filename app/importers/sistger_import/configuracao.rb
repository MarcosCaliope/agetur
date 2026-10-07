require "open3"
require "timeout"

class SistgerImport
  # Where to connect. Each setting comes from its SISTGER_DB_* environment
  # variable when set, otherwise from the Windows registry key the legacy
  # SISTGER client uses (readable from WSL through reg.exe). In production
  # (Linux, no reg.exe) only the environment variables apply.
  class Configuracao
    CHAVE_REGISTRO = 'HKCU\SOFTWARE\VB and VBA Program Settings\oServico\BANCO_DE_DADOS'.freeze
    REG_EXE = ["reg.exe", "/mnt/c/Windows/system32/reg.exe"].freeze

    attr_reader :host, :instancia, :porta, :banco, :usuario, :senha, :origens

    def self.carregar(env: ENV, registro: nil)
      new(env: env, registro: registro || ler_registro(env))
    end

    # Registry values as {"DATA_SOURCE" => ..., "USER_ID" => ...}; {} when the
    # registry isn't reachable or SISTGER_DB_REGISTRO=off.
    def self.ler_registro(env = ENV)
      return {} if env["SISTGER_DB_REGISTRO"] == "off"

      reg = REG_EXE.find { |cmd| cmd.include?("/") ? File.exist?(cmd) : system("command -v #{cmd} >/dev/null 2>&1") }
      return {} unless reg

      saida, status = Timeout.timeout(10) { Open3.capture2e(reg, "query", CHAVE_REGISTRO) }
      return {} unless status.success?

      # Lines look like "    DATA_SOURCE    REG_SZ    mynt\sqlexpress" (value may be empty).
      saida.delete("\r").scan(/^\s+(\S+)\s+REG_\w+[ \t]*(.*)$/).to_h
    rescue Timeout::Error, SystemCallError
      {}
    end

    def initialize(env:, registro:)
      @origens = {}
      servidor, instancia = registro["DATA_SOURCE"].to_s.split("\\", 2)

      @host = valor(env, "SISTGER_DB_HOST", servidor.presence, :host)
      @instancia = instancia.presence unless env["SISTGER_DB_HOST"].present? || env["SISTGER_DB_PORT"].present?
      @porta = env["SISTGER_DB_PORT"].presence&.then { |p| Integer(p) }
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

    # Named instances (mynt\sqlexpress) are resolved by the SQL Browser
    # service; an explicit port skips it.
    def servidor
      instancia ? "#{host}\\#{instancia}" : "#{host}:#{porta || 1433}"
    end

    def descricao
      "#{servidor}, banco #{banco}" + (usa_registro? ? " (registro do Windows)" : "")
    end

    def parametros_conexao
      base = { database: banco, username: usuario, password: senha }
      instancia ? base.merge(dataserver: servidor) : base.merge(host: host, port: porta || 1433)
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
