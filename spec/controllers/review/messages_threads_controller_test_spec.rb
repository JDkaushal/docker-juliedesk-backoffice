require_relative "../../rails_helper"

describe Review::MessagesThreadsController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin')
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com')
    @normal.password= 'op'
    @normal.save

    @user_non_admin = @normal.email
    @user_admin = @admin.email
    @pw = 'op'
  end

  describe 'Inheritance' do
    it { expect(described_class).to be < ReviewController }
  end

  describe 'Actions' do

    before(:each) do
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_admin,@pw)
    end

    describe 'Review' do

      it 'should process the desired messages Thread and populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :review, id: mt1.id
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      it 'should calculate the correct to review count' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :review, id: mt1.id
        expect(assigns(:to_review_count)).to eq(3)
      end

      it 'should calculate the correct to review count when some operator actions groups are not related to any operators' do

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
        OperatorActionsGroup.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :review, id: mt1.id
        expect(assigns(:to_review_count)).to eq(2)
      end
    end

    describe 'Learn' do

      describe 'Permission' do
        it 'should be accessible to admin operators' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
          expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

          get :learn, id: mt1.id
          expect(assigns(:messages_thread)).to eq(mt1)
        end

        it 'should be accessible to the specified operator even if non admin' do
          @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)

          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
          expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

          get :learn, id: mt1.id, operator_id: @normal.id
          expect(assigns(:messages_thread)).to eq(mt1)
        end

        # Need to check the only_mine before filter to decide if there must be a redirection when the test fail
        it 'should not be accessible to a normal operator that is not specified by its id' do
          op1 = FactoryGirl.create(:operator_actif)

          @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)

          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          get :learn, id: mt1.id, operator_id: op1.id
          expect(response.code).to eq("302")
          expect(response).to redirect_to("/")
        end
      end

      it 'should process the desired messages Thread and populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :learn, id: mt1.id
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      it 'should calculate the correct to learn count' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :learn, id: mt1.id, operator_id: op1.id
        expect(assigns(:to_learn_count)).to eq(3)
      end
    end

    describe 'Group_review' do

      it 'should process the desired messages Thread and populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :group_review, id: mt1.id
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      it 'should calculate the correct to learn count' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        op1.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt3.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt4.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        expect_any_instance_of(MessagesThread).to receive(:re_import).and_return(true)
        expect_any_instance_of(MessagesThread).to receive(:account).and_return(true)

        get :group_review, id: mt1.id
        expect(assigns(:to_group_review_count)).to eq(3)
      end
    end

    describe 'Learnt' do
      describe 'Permission' do
        it 'should be accessible to admin operators' do
          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          post :learnt, id: mt1.id
          expect(assigns(:messages_thread)).to eq(mt1)
        end

        it 'should be accessible to the specified operator even if non admin' do
          @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)

          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          post :learnt, id: mt1.id, operator_id: @normal.id
          expect(assigns(:messages_thread)).to eq(mt1)
        end

        # Need to check the only_mine before filter to decide if there must be a redirection when the test fail
        it 'should not be accessible to a normal operator that is not specified by its id' do
          @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)

          mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

          post :learnt, id: mt1.id, operator_id: @admin.id
          expect(response.code).to eq("302")
          expect(response).to redirect_to('/')
        end
      end

      it 'should update the correct operator action group to learnt status' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        post :learnt, id: mt2.id, operator_id: op1.id
        expect(oag1.reload.review_status).to eq(OperatorActionsGroup::REVIEW_STATUS_LEARNT)
      end

      it 'should not update the operator action group if it s operator id is not provided' do

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        post :learnt, id: mt2.id, operator_id: op2.id
        expect(oag1.reload.review_status).not_to eq(OperatorActionsGroup::REVIEW_STATUS_LEARNT)
      end

      it 'should redirect the operator to the next learning thread' do

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2015,9,11))
        oag3 = op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2015,9,13))
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        post :learnt, id: mt2.id, operator_id: op1.id
        expect(response).to redirect_to("/review/messages_threads/#{oag2.messages_thread_id}/learn?operator_id=#{op1.id}")
      end

      it 'should redirect the operator to its stat page if no operator action group is available for learning' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        op2.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        post :learnt, id: mt2.id, operator_id: op1.id
        expect(response).to redirect_to(my_stats_review_operators_path)
      end
    end

    describe 'Reviewed' do
      it 'should process the desired messages Thread and populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

        post :reviewed, id: mt1.id, data: "[{\"x\":1},{\"y\":3}]"
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      it 'should update the correct operator action groups' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)
        op4 = FactoryGirl.create(:operator_actif)
        op5 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2015,9,11))
        op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2015,9,13))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN)

        post :reviewed, id: mt2.id, data: [{operator_actions_group_id: oag1.id, notation: 5, comment: 'Comment'}, {operator_actions_group_id: oag2.id, notation: 4, comment: 'Comment 2'}, {operator_actions_group_id: oag3.id, notation: 3, should_review_in_group: true, comment: 'Comment 3'}].to_json

        oag1.reload
        oag2.reload
        oag3.reload

        expect([oag1.review_status, oag1.review_notation, oag1.group_review_status, oag1.review_comment]).to eq([OperatorActionsGroup::REVIEW_STATUS_REVIEWED, 5, OperatorActionsGroup::GROUP_REVIEW_STATUS_UNSET, 'Comment\n\n'])
        expect([oag2.review_status, oag2.review_notation, oag2.group_review_status, oag2.review_comment]).to eq([OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, 4, OperatorActionsGroup::GROUP_REVIEW_STATUS_UNSET, 'Comment 2\n\n'])
        expect([oag3.review_status, oag3.review_notation, oag3.group_review_status, oag3.review_comment]).to eq([OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, 3, OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, 'Comment 3\n\n'])
      end

      it 'should close the tab after execution' do
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        post :reviewed, id: mt2.id, data: [{test: 'test'}].to_json
        expect(response.body).to eq("<script>window.close();</script>")
      end
    end

    describe 'Group Reviewed' do
      it 'should process the desired messages Thread and populate the correct instance variables' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)

        post :group_reviewed, id: mt1.id
        expect(assigns(:messages_thread)).to eq(mt1)
      end

      it 'should update the correct operator action groups' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
        oag4 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)

        post :group_reviewed, id: mt1.id

        oag1.reload
        oag2.reload
        oag3.reload
        oag4.reload

        expect(oag1.group_review_status).to eq(OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT)
        expect(oag2.group_review_status).to eq(OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT)
        expect(oag3.group_review_status).to eq(OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT)
        expect(oag4.group_review_status).to eq(OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
      end

      it 'should redirect the operator to the next group review' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))
        oag4 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,10,11))

        post :group_reviewed, id: mt1.id

        expect(response).to redirect_to("/review/messages_threads/#{oag4.messages_thread_id}/group_review")
      end

      it 'should redirect the operator to the review index' do

        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))

        post :group_reviewed, id: mt1.id

        expect(response).to redirect_to(review_operators_path)
      end
    end

    describe 'Review next' do
      it 'should redirect the operator to the next review if a messages thread is available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))

        get :review_next

        expect(response).to redirect_to("/review/messages_threads/#{oag1.messages_thread_id}/review")
      end

      it 'should redirect the operator to the review index if no operator action group are available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_REVIEWED, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_REVIEWED, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_REVIEWED, initiated_at: DateTime.new(2014,9,13))

        get :review_next

        expect(response).to redirect_to(review_operators_path)
      end
    end

    describe 'Group Review next' do
      it 'should redirect the operator to the next review if a messages thread is available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))

        get :group_review_next

        expect(response).to redirect_to("/review/messages_threads/#{oag1.messages_thread_id}/group_review")
      end

      it 'should redirect the operator to the review index if no operator action group are available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,13))

        get :group_review_next

        expect(response).to redirect_to(review_operators_path)
      end
    end

    describe 'Learn next' do
      it 'should redirect the operator to the next review if a messages thread is available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = op1.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))

        get :learn_next, operator_id: op1.id

        expect(response).to redirect_to("/review/messages_threads/#{oag1.messages_thread_id}/learn?operator_id=#{oag1.operator_id}")
      end

      it 'should redirect the operator to the review index if no operator action group are available' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)

        op1 = FactoryGirl.create(:operator_actif)
        op2 = FactoryGirl.create(:operator_actif)
        op3 = FactoryGirl.create(:operator_actif)

        oag1 = op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,11))
        oag2 = op2.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,12))
        oag3 = op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT, initiated_at: DateTime.new(2014,9,13))

        get :learn_next, operator_id: op1.id

        expect(response).to redirect_to(my_stats_review_operators_path)
      end
    end

  end
end