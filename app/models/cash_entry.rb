# A cash book entry (SISTGER's cx_num + cx_mov line). Entries made by a
# passenger payment or a paid bill come and go with them (see #automatico?);
# the others are typed in the Caixa screen.
class CashEntry < ApplicationRecord
  TIPOS = { "E" => "Entrada", "S" => "Saída" }.freeze
  FORMAS = { "D" => "Dinheiro", "O" => "PIX", "C" => "Cartão de débito", "R" => "Cartão de crédito", "T" => "Transferência" }.freeze
  CATEGORIAS = ["Recebimento de passeio", "Pagamento de conta", "Suprimento", "Sangria", "Despesa", "Outros"].freeze

  belongs_to :sorder, optional: true
  belongs_to :sorder_item, optional: true
  has_one :pagamento, class_name: "SorderItemPayment", dependent: :nullify
  has_many :payables, dependent: :nullify # one, or a batch of commissions

  validates :data, :descricao, :categoria, presence: true
  validates :tipo, inclusion: { in: TIPOS.keys }
  validates :forma_pagamento, inclusion: { in: FORMAS.keys }
  validates :valor, numericality: { greater_than: 0 }

  scope :entradas, -> { where(tipo: "E") }
  scope :saidas, -> { where(tipo: "S") }

  # Entries in minus exits.
  def self.saldo
    sum("CASE WHEN tipo = 'E' THEN valor ELSE -valor END")
  end

  def entrada?
    tipo == "E"
  end

  def valor_com_sinal
    entrada? ? valor : -valor
  end

  # Made by a passenger payment or a paid bill: undone from there, not here.
  def automatico?
    pagamento.present? || payables.any?
  end

  def nome_tipo = TIPOS[tipo]
  def nome_forma = FORMAS[forma_pagamento]
end
