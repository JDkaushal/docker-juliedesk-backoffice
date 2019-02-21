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
      expect(controller).to receive(:jd_auth_authenticate_server).at_least(:once).and_return(true)


      @op1 = FactoryGirl.create(:operator_actif)
      @op2 = FactoryGirl.create(:operator_actif)
      @op3 = FactoryGirl.create(:operator_actif)
      @op4 = FactoryGirl.create(:operator_actif)
      @op5 = FactoryGirl.create(:operator_actif)

    end

    describe 'index' do
      it 'should access the index page if the operator has admin privileges' do
        expect(EmailServer).to receive(:search_messages).and_return({
                                                                        'messages' => {
                                                                            'ids' => []
                                                                        }
                                                                    })

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :index
        expect(response).to render_template(:index)
      end

      it 'should not access the index page if the operator has not admin privileges' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))

        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'My stats' do

      it 'should be accessible to a non admin operator' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
        get :my_stats
        expect(response).to render_template(:my_stats)
      end

      it 'should find the current operator in session' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_non_admin))
        get :my_stats
        expect(assigns(:operator)).to eq(@normal)
      end
    end

    describe 'Show' do

      it 'should set the correct operator' do

        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :show, params: { id: @op1.id }

        expect(assigns(:operator)).to eq(@op1)
      end

      it 'should set the current operator variable to nil if all operators are requested' do
        expect(controller).to receive(:jd_auth_current_user).at_least(:once).and_return(OpenStruct.new(email: @user_admin))

        get :show, params: { id: 'all' }
        expect(assigns(:operator)).to be(nil)
      end
    end

  end
end