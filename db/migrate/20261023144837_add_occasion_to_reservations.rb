class AddOccasionToReservations < ActiveRecord::Migration[8.1]
  def change
    add_reference :reservations, :occasion, foreign_key: { on_delete: :nullify }
  end
end
