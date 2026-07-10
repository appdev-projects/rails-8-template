require "rails_helper"

RSpec.describe ApplicationJob do
  it "defers enqueues until the surrounding transaction commits" do
    expect(described_class.enqueue_after_transaction_commit).to be(true)
  end
end
