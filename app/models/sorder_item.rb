class SorderItem < ApplicationRecord
  belongs_to :sorder
  belongs_to :customer
  belongs_to :hotel
  belongs_to :vendor

  def total_receber
#    return amountcomission - amountcomissionpay if amountcomission.present? && amountcomissionpay.present?
#    "0,00"
    return amountcomission - amountcomissionpay if amountcomissionpay.present?
    amountcomission
  end
end
