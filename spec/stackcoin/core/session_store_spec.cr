require "../../spec_helper"
require "../../../src/stackcoin/core/session_store"

describe "StackCoin::Core::SessionStore" do
  [
    {0, 1.minute, false},
    {10, 2.minute, true},
    {99, 10.hours, false},
  ].each do |user_id, valid_for, one_time_use|
    it "generates a session token with a user_id of #{user_id}, valid_for of #{valid_for}, one_time_use of #{one_time_use}" do
      rollback_once_finished do |tx|
        id, session = StackCoin::Core::SessionStore.create(user_id, valid_for, one_time_use)

        session.user_id.should eq user_id
        session.one_time_use.should eq one_time_use
      end
    end
  end
end
