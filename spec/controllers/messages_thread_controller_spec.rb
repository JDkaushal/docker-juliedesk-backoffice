require_relative "../rails_helper"

describe MessagesThreadsController, :type => :controller do

  before(:each) do
    @messages_thread = FactoryGirl.create(:messages_thread_with_messages)

    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true, ips_whitelist_enabled: false)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op', ips_whitelist_enabled: false)
    @normal.password= 'op'
    @normal.save

    @user_non_admin = @normal.email
    @user_admin = @admin.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ApplicationController }
  end

  describe 'Actions' do

    before(:each) do
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)
      expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
    end

    describe 'set_to_be_merged' do

      it 'should set the thread to_be_merged boolean to true' do
        @messages_thread.update(to_be_merged: false)

        post :set_to_be_merged, id: @messages_thread.id, to_merge: true

        @messages_thread.reload

        expect(@messages_thread.to_be_merged).to be(true)

      end

      it 'should set the thread to_be_merged boolean to false' do
        @messages_thread.update(to_be_merged: true)

        post :set_to_be_merged, id: @messages_thread.id, to_merge: false

        @messages_thread.reload

        expect(@messages_thread.to_be_merged).to be(false)

      end

    end



  end


end