class ChargesController < ApplicationController
  before_action :require_login, only: [:new]

  def new
    @purchase = Purchase.find(params[:purchase])
    @letter   = Letter.find(@purchase.letter_id)
  end

  def create
    @amount = 100
    
    customer = Stripe::Customer.create(
      :email  => params[:stripeEmail],
      :source => params[:stripeToken]
    )

    charge = Stripe::Charge.create(
      :customer     => customer.id,
      :amount       => @amount,
      :description  => "Purchase ID: ",
      :currency     => 'usd'
    )

    if charge.status == "succeeded"
      purchase = Purchase.find(params[:purchase_id])
      purchase.update_attributes(payment_status: "paid")
      politician = Politician.new.donald_trump
      response = purchase.order_letter(lob, politician)
      Letter.find(purchase.letter_id).update_attributes(status: "en route", expected_delivery_date: response["expected_delivery_date"], picture_url: response["url"] )
    end

    rescue Stripe::CardError => e 
      flash[:error] = e.message
      redirect_to new_charge_path
  end

  private

  def require_login
    if current_user.nil? || params[:purchase].nil?
      flash[:danger] = "you're not allowed on that page"
      redirect_to root_path
    end
  end
end 