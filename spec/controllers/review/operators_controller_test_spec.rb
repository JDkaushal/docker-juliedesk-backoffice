require_relative "../../rails_helper"

describe Review::OperatorsController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true, ips_whitelist_enabled: false)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, ips_whitelist_enabled: false)
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

      @op1 = FactoryGirl.create(:operator_actif)
      @op2 = FactoryGirl.create(:operator_actif)
      @op3 = FactoryGirl.create(:operator_actif)
      @op4 = FactoryGirl.create(:operator_actif)
      @op5 = FactoryGirl.create(:operator_actif)

    end

    describe 'Index' do
      it 'should access the index page if the operator has admin privileges' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'should not access the index page if the operator has not admin privileges' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        get :index
        expect(response).to redirect_to(root_path)
      end

      it 'should compute the counts' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

        oag1 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag4 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag5 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag2 = @op2.operator_actions_groups.create(messages_thread_id: mt5.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,12))
        oag3 = @op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))
        oag6 = @op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))

        oag1 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag4 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag5 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = @op2.operator_actions_groups.create(messages_thread_id: mt5.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = @op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))
        oag6 = @op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))

        oag1 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag4 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag5 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,11))
        oag2 = @op2.operator_actions_groups.create(messages_thread_id: mt5.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,12))
        oag3 = @op3.operator_actions_groups.create(messages_thread_id: mt2.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))
        oag6 = @op3.operator_actions_groups.create(messages_thread_id: mt4.id, group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN, initiated_at: DateTime.new(2014,9,13))

        get :index

        expect(assigns(:operators)).to eq(Operator.all)
        expect(assigns(:to_review_count)).to eq(5)

        oags_to_review_counts = assigns(:oags_to_review_counts)

        expect([oags_to_review_counts[@op1.id], oags_to_review_counts[@op2.id], oags_to_review_counts[@op3.id] ]).to eq([3, 1, 2])

        expect(assigns(:to_group_review_count)).to eq(5)

        oags_to_learn_counts = assigns(:oags_to_learn_counts)

        expect([oags_to_learn_counts[@op1.id], oags_to_learn_counts[@op2.id], oags_to_learn_counts[@op3.id], oags_to_learn_counts['all']]).to eq([3, 1, 2, 6])

      end
    end

    describe 'My stats' do

      it 'should be accessible to a non admin operator' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        get :my_stats
        expect(response).to render_template(:my_stats)
      end

      it 'should find the current operator in session' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        get :my_stats
        expect(assigns(:operator)).to eq(@normal)
      end
    end

    describe 'Show' do

      it 'should call compute_counts' do
        expect(controller).to receive(:compute_counts)

        get :show, id: @op1.id
      end

      it 'should set the correct operator' do
        get :show, id: @op1.id

        expect(assigns(:operator)).to eq(@op1)
      end

      it 'should set the current operator variable to nil if all operators are requested' do
        get :show, id: 'all'
        expect(assigns(:operator)).to be(nil)
      end
    end

    describe 'Review list' do
      it 'should call compute_counts' do
        expect(controller).to receive(:compute_counts)

        get :review_list
      end

      it 'should populate the correct instance variables for all operators' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

        oag1 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag4 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag5 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag2 = @op2.operator_actions_groups.create(messages_thread_id: mt5.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,12))
        oag3 = @op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))
        oag6 = @op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))
        oag7 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11), label: "ask_create_event")
        oag8 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11), label: "ask_create_event")
        oag9 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11), label: "ask_create_event")

        get :review_list

        expect(assigns(:created_events_messages_thread_ids)).to eq([mt1.id, mt3.id, mt4.id])

        expect(assigns(:messages_threads)).to eq([mt1, mt3, mt4, mt5, mt2])
      end

      it 'should populate the correct instance variables for some specified operators' do
        mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
        mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

        oag1 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,11))
        oag4 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,12))
        oag5 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,13))
        oag2 = @op2.operator_actions_groups.create(messages_thread_id: mt5.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,14))
        oag3 = @op3.operator_actions_groups.create(messages_thread_id: mt2.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,15))
        oag6 = @op3.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,16))
        oag7 = @op1.operator_actions_groups.create(messages_thread_id: mt1.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,17), label: "ask_create_event")
        oag8 = @op1.operator_actions_groups.create(messages_thread_id: mt3.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,18), label: "ask_create_event")
        oag9 = @op1.operator_actions_groups.create(messages_thread_id: mt4.id, review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, initiated_at: DateTime.new(2014,9,19), label: "ask_create_event")

        get :review_list, operator_id: [@op1.id, @op2.id]

        expect(assigns(:created_events_messages_thread_ids)).to eq([mt1.id, mt3.id, mt4.id])

        expect(assigns(:messages_threads)).to eq([mt1, mt3, mt4, mt5])
      end
    end

    describe 'Events Review List' do
      it 'should call compute_counts' do
        expect(controller).to receive(:compute_counts)
        get :events_review_list
      end

      it 'should get the corrects event title reviews' do
        etr1 = FactoryGirl.create(:event_title_review_status_nil)
        etr2 = FactoryGirl.create(:event_title_review_status_nil)
        etr3 = FactoryGirl.create(:event_title_review_status_nil)
        etr4 = FactoryGirl.create(:event_title_review_status_nil)
        etr5 = FactoryGirl.create(:event_title_review_status_not_nil)
        etr6 = FactoryGirl.create(:event_title_review_status_not_nil)

        get :events_review_list
        expect(assigns(:event_title_reviews).map(&:id)).to eq([etr1.id, etr2.id, etr3.id, etr4.id])
      end
    end

    describe 'Review Event Titles' do

      it 'should get the corrects event title reviews' do
        etr1 = FactoryGirl.create(:event_title_review_status_nil)
        etr2 = FactoryGirl.create(:event_title_review_status_nil)
        etr3 = FactoryGirl.create(:event_title_review_status_nil)
        etr4 = FactoryGirl.create(:event_title_review_status_nil)
        etr5 = FactoryGirl.create(:event_title_review_status_not_nil)
        etr6 = FactoryGirl.create(:event_title_review_status_not_nil)

        get :review_event_titles

        etr1.reload
        etr2.reload
        etr3.reload
        etr4.reload

        expect(etr1.status).to eq(EventTitleReview::STATUS_REVIEWED)
        expect(etr2.status).to eq(EventTitleReview::STATUS_REVIEWED)
        expect(etr3.status).to eq(EventTitleReview::STATUS_REVIEWED)
        expect(etr4.status).to eq(EventTitleReview::STATUS_REVIEWED)
      end

      it 'should redirect the operator to the correct page' do
        get :review_event_titles
        expect(response).to redirect_to('/review/operators/events_review_list')
      end
    end
  end
end