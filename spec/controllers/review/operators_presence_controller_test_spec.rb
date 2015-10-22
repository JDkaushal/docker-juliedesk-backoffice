require_relative "../../rails_helper"

describe Review::OperatorsPresenceController, :type => :controller do

  before(:each) do
    @admin = Operator.new(email: 'admin@op.com', privilege: 'admin', active: true)
    @admin.password= 'op'
    @admin.save

    @normal = Operator.new(email: 'normal@op.com', active: true, name: 'normal op')
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
      render_views

      it 'should access the index page if the operator has admin privileges' do
        get :index
        expect(response).to render_template(:index)
      end

      it 'should not access the index page if the operator has not admin privileges' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        get :index
        expect(response).to redirect_to(root_path)
      end

      it 'should return the correct html if no start parameter is provided' do
        get :index
        expect(response.body).to eq("<!DOCTYPE html>\n<html>\n<head>\n  <title>JuliedeskBackoffice</title>\n  <link href=\"/favicon.ico\" rel=\"shortcut icon\" type=\"image/vnd.microsoft.icon\" />\n  <link href=\"/assets/application.css\" media=\"all\" rel=\"stylesheet\" />\n  <script src=\"/assets/application.js\"></script>\n  \n</head>\n<body>\n<script>\n    var presenceFormat = \"YYYYMMDDTHH0000\";\n    var app = angular.module(\"backofficeApp\", []);\n    app.controller(\"OperatorsPresenceCtrl\", function($scope, $http, $sce) {\n\n\n        $scope.startWeekDate = moment.tz('Indian/Antananarivo').startOf(\"isoweek\").utc().add(6, 'h');\n        $scope.endWeekDate = $scope.startWeekDate.clone().endOf(\"isoweek\");\n\n        // Based on september\n        //$scope.countsToMatch = {\"100\":1,\"101\":1,\"102\":1,\"103\":1,\"104\":1,\"105\":1,\"106\":2,\"107\":2,\"108\":3,\"109\":3,\"110\":3,\"111\":2,\"112\":4,\"113\":4,\"114\":4,\"115\":4,\"116\":3,\"117\":3,\"118\":3,\"119\":2,\"120\":2,\"121\":2,\"122\":1,\"123\":1,\"200\":1,\"201\":1,\"202\":1,\"203\":1,\"204\":1,\"205\":1,\"206\":2,\"207\":3,\"208\":3,\"209\":3,\"210\":2,\"211\":2,\"212\":3,\"213\":3,\"214\":3,\"215\":4,\"216\":4,\"217\":3,\"218\":3,\"219\":2,\"220\":1,\"221\":2,\"222\":1,\"223\":1,\"300\":1,\"301\":1,\"302\":1,\"303\":1,\"304\":1,\"305\":1,\"306\":2,\"307\":2,\"308\":3,\"309\":4,\"310\":3,\"311\":2,\"312\":3,\"313\":4,\"314\":4,\"315\":4,\"316\":3,\"317\":3,\"318\":3,\"319\":2,\"320\":2,\"321\":2,\"322\":2,\"323\":1,\"400\":1,\"401\":1,\"402\":1,\"403\":1,\"404\":1,\"405\":2,\"406\":2,\"407\":3,\"408\":4,\"409\":3,\"410\":3,\"411\":3,\"412\":3,\"413\":4,\"414\":3,\"415\":4,\"416\":3,\"417\":3,\"418\":2,\"419\":2,\"420\":2,\"421\":1,\"422\":1,\"423\":1,\"500\":1,\"501\":1,\"502\":1,\"503\":1,\"504\":1,\"505\":1,\"506\":2,\"507\":3,\"508\":3,\"509\":3,\"510\":2,\"511\":2,\"512\":3,\"513\":4,\"514\":2,\"515\":4,\"516\":3,\"517\":2,\"518\":1,\"519\":1,\"520\":1,\"521\":1,\"522\":1,\"523\":1,\"600\":1,\"601\":1,\"602\":1,\"603\":0,\"604\":1,\"605\":1,\"606\":1,\"607\":1,\"608\":1,\"609\":1,\"610\":1,\"611\":1,\"612\":1,\"613\":1,\"614\":1,\"615\":1,\"616\":1,\"617\":1,\"618\":1,\"619\":1,\"620\":1,\"621\":1,\"622\":1,\"623\":0,\"700\":1,\"701\":1,\"702\":0,\"703\":0,\"704\":0,\"705\":0,\"706\":0,\"707\":1,\"708\":1,\"709\":1,\"710\":1,\"711\":1,\"712\":1,\"713\":1,\"714\":1,\"715\":1,\"716\":1,\"717\":1,\"718\":1,\"719\":1,\"720\":1,\"721\":1,\"722\":1,\"723\":1};\n\n        // Based on october\n        // $scope.countsToMatch = {\"100\":1,\"101\":1,\"102\":1,\"103\":0,\"104\":1,\"105\":1,\"106\":1,\"107\":1,\"108\":3,\"109\":4,\"110\":4,\"111\":3,\"112\":3,\"113\":4,\"114\":4,\"115\":5,\"116\":4,\"117\":3,\"118\":4,\"119\":3,\"120\":2,\"121\":2,\"122\":3,\"123\":1,\"200\":1,\"201\":1,\"202\":1,\"203\":1,\"204\":1,\"205\":1,\"206\":1,\"207\":2,\"208\":4,\"209\":4,\"210\":4,\"211\":3,\"212\":3,\"213\":4,\"214\":5,\"215\":4,\"216\":6,\"217\":5,\"218\":4,\"219\":3,\"220\":2,\"221\":2,\"222\":2,\"223\":2,\"300\":1,\"301\":1,\"302\":1,\"303\":1,\"304\":1,\"305\":1,\"306\":1,\"307\":1,\"308\":3,\"309\":3,\"310\":3,\"311\":3,\"312\":1,\"313\":3,\"314\":3,\"315\":4,\"316\":4,\"317\":5,\"318\":3,\"319\":2,\"320\":1,\"321\":2,\"322\":2,\"323\":1,\"400\":1,\"401\":1,\"402\":1,\"403\":1,\"404\":1,\"405\":1,\"406\":1,\"407\":1,\"408\":3,\"409\":3,\"410\":4,\"411\":3,\"412\":3,\"413\":3,\"414\":4,\"415\":5,\"416\":4,\"417\":5,\"418\":4,\"419\":3,\"420\":3,\"421\":3,\"422\":2,\"423\":2,\"500\":1,\"501\":1,\"502\":1,\"503\":1,\"504\":1,\"505\":1,\"506\":1,\"507\":2,\"508\":3,\"509\":3,\"510\":4,\"511\":3,\"512\":2,\"513\":3,\"514\":4,\"515\":4,\"516\":4,\"517\":4,\"518\":3,\"519\":2,\"520\":2,\"521\":2,\"522\":1,\"523\":1,\"600\":1,\"601\":1,\"602\":1,\"603\":1,\"604\":1,\"605\":1,\"606\":1,\"607\":1,\"608\":1,\"609\":1,\"610\":1,\"611\":1,\"612\":1,\"613\":1,\"614\":1,\"615\":1,\"616\":1,\"617\":1,\"618\":1,\"619\":1,\"620\":1,\"621\":1,\"622\":1,\"623\":1,\"700\":1,\"701\":1,\"702\":0,\"703\":1,\"704\":1,\"705\":1,\"706\":0,\"707\":0,\"708\":1,\"709\":1,\"710\":1,\"711\":1,\"712\":1,\"713\":1,\"714\":1,\"715\":2,\"716\":1,\"717\":1,\"718\":1,\"719\":1,\"720\":1,\"721\":1,\"722\":1,\"723\":1};\n        $scope.countsToMatch = {\"100\":1,\"101\":1,\"102\":0,\"103\":1,\"104\":1,\"105\":1,\"106\":1,\"107\":3,\"108\":4,\"109\":5,\"110\":4,\"111\":3,\"112\":3,\"113\":4,\"114\":6,\"115\":4,\"116\":5,\"117\":5,\"118\":4,\"119\":2,\"120\":2,\"121\":3,\"122\":2,\"123\":1,\"200\":1,\"201\":1,\"202\":1,\"203\":1,\"204\":1,\"205\":1,\"206\":2,\"207\":3,\"208\":4,\"209\":3,\"210\":3,\"211\":3,\"212\":4,\"213\":5,\"214\":5,\"215\":6,\"216\":5,\"217\":5,\"218\":4,\"219\":3,\"220\":2,\"221\":2,\"222\":2,\"223\":1,\"300\":2,\"301\":1,\"302\":1,\"303\":1,\"304\":1,\"305\":1,\"306\":1,\"307\":2,\"308\":3,\"309\":4,\"310\":3,\"311\":3,\"312\":4,\"313\":4,\"314\":5,\"315\":5,\"316\":5,\"317\":4,\"318\":3,\"319\":2,\"320\":2,\"321\":2,\"322\":2,\"323\":2,\"400\":1,\"401\":1,\"402\":1,\"403\":1,\"404\":1,\"405\":1,\"406\":1,\"407\":2,\"408\":3,\"409\":4,\"410\":4,\"411\":3,\"412\":3,\"413\":5,\"414\":5,\"415\":5,\"416\":5,\"417\":4,\"418\":3,\"419\":3,\"420\":3,\"421\":3,\"422\":2,\"423\":1,\"500\":1,\"501\":1,\"502\":1,\"503\":1,\"504\":1,\"505\":1,\"506\":1,\"507\":3,\"508\":3,\"509\":3,\"510\":4,\"511\":2,\"512\":3,\"513\":3,\"514\":4,\"515\":4,\"516\":4,\"517\":3,\"518\":2,\"519\":2,\"520\":2,\"521\":1,\"522\":1,\"523\":1,\"600\":1,\"601\":1,\"602\":1,\"603\":1,\"604\":1,\"605\":1,\"606\":1,\"607\":1,\"608\":1,\"609\":1,\"610\":1,\"611\":1,\"612\":1,\"613\":1,\"614\":1,\"615\":1,\"616\":1,\"617\":1,\"618\":1,\"619\":1,\"620\":1,\"621\":1,\"622\":1,\"623\":1,\"700\":0,\"701\":1,\"702\":1,\"703\":1,\"704\":1,\"705\":0,\"706\":0,\"707\":0,\"708\":1,\"709\":1,\"710\":1,\"711\":1,\"712\":1,\"713\":1,\"714\":1,\"715\":1,\"716\":1,\"717\":1,\"718\":1,\"719\":1,\"720\":1,\"721\":1,\"722\":1,\"723\":1};\n        $scope.o = {};\n\n        $scope.setHours = function() {\n            $scope.hours = [];\n            for(var i=0; i < 24*7; i++) {\n                var mTime = $scope.startWeekDate.clone();\n                mTime.add(i, 'h');\n                $scope.hours.push(mTime);\n            }\n        };\n        $scope.setHours();\n\n        $scope.previousWeek = function() {\n            $scope.startWeekDate.add(-1, 'w');\n            $scope.setHours();\n            $scope.fetch();\n        };\n\n        $scope.nextWeek = function() {\n            $scope.startWeekDate.add(1, 'w');\n            $scope.setHours();\n            $scope.fetch();\n        };\n\n        $scope.fetch = function() {\n            $scope.loading = true;\n            $http.get(\"operators_presence.json?start=\" + $scope.startWeekDate.format()).success(function(response) {\n                $scope.operators = response.data.operators;\n                $scope.loading = false;\n            });\n        };\n\n        $scope.getHours = function(weekDay) {\n            return _.filter($scope.hours, function(hour) {\n                return hour.clone().tz('Indian/Antananarivo').add(-6, 'h').isoWeekday() == weekDay;\n            });\n        };\n\n        $scope.fetch();\n\n\n        $scope.endTogglePresences = function(operator, presence) {\n            var formattedPresence = presence.format(presenceFormat);\n            if($scope.initDrag && $scope.initDrag.operator == operator) {\n                var presences = _.select(_.map($scope.hours, function(mHour) {\n                    return mHour.format(presenceFormat);\n                }), function(formattedHour) {\n                    return formattedHour <= formattedPresence && formattedHour >= $scope.initDrag.presence.format(presenceFormat);\n                });\n\n                var allSelected = true;\n                _.each(presences, function(presence) {\n                    allSelected = allSelected && operator.presences.indexOf(presence) > -1;\n                });\n\n\n                if(allSelected) {\n                    _.each(presences, function(presence) {\n                        var index = operator.presences.indexOf(presence);\n                        if(index > -1) {\n                            operator.presences.splice(index, 1);\n                        }\n                    });\n\n                    $scope.loading = true;\n                    $.post(\"/review/operators_presence/remove\", {\n                        presences: presences,\n                        operator_id: operator.id\n                    }).success(function() {\n                                $scope.loading = false;\n                                $scope.$apply()\n                            });\n                }\n                else {\n                    _.each(presences, function(presence) {\n                        var index = operator.presences.indexOf(presence);\n                        if(index == -1) {\n                            operator.presences.push(presence);\n                        }\n                    });\n\n                    $scope.loading = true;\n                    $.post(\"/review/operators_presence/add\", {\n                        presences: presences,\n                        operator_id: operator.id\n                    }).success(function() {\n                                $scope.loading = false;\n                                $scope.$apply();\n                            });\n                }\n            }\n            $scope.initDrag = null;\n        };\n\n        $scope.isOperatorPresent = function(operator, presence) {\n            return operator.presences.indexOf(presence.format(presenceFormat)) > -1;\n        };\n\n        $scope.resetDay = function(weekDay) {\n            $scope.loading = true;\n            $.post(\"/review/operators_presence/reset_day\", {\n                day: $scope.startWeekDate.clone().add(weekDay - 1, 'd').format()\n            }).success(function() {\n                        $scope.fetch();\n                    });\n\n        };\n\n        $scope.copyDay = function(weekDay, days) {\n            $scope.loading = true;\n            $.post(\"/review/operators_presence/copy_day\", {\n                day: $scope.startWeekDate.clone().add(weekDay - 1, 'd').format(),\n                days: days\n            }).success(function() {\n                        $scope.fetch();\n                    });\n\n        };\n\n        $scope.initTogglePresences = function(operator, presence) {\n            $scope.initDrag = {\n                operator: operator,\n                presence: presence\n            };\n        };\n\n        $scope.countsForHour = function(hour) {\n            var result = 0;\n            _($scope.operators).each(function(operator) {\n                if($scope.isOperatorPresent(operator, hour)) {\n                    result += 1;\n                }\n            });\n            return result;\n        };\n\n        $scope.countsToMatchForHour = function(hour) {\n            return $scope.countsToMatch[hour.format(\"EHH\")];\n        };\n    });\n</script>\n\n<style>\n    .operators-presence-container {\n        width: 984px;\n        margin: 20px auto 0 auto;\n    }\n\n    .operators-presence-container .table-container {\n        position: relative;\n    }\n    .operators-presence-container table {\n        overflow-x:visible;\n        overflow-y:visible;\n        width: 984px;\n        display: block;\n    }\n\n    .operators-presence-container table tr th.hour {\n        font-size: 12px;\n        font-weight: 400;\n    }\n    .operators-presence-container table tr th.hour.main-of-day {\n        font-weight: 800;\n        background: #C1E2F5;\n    }\n    .operators-presence-container table tr td {\n        cursor: pointer;\n        height: 20px;\n        line-height: 20px;\n        padding: 0;\n        font-size: 12px;\n    }\n    .operators-presence-container table tr th {\n        height: 60px;\n    }\n    .operators-presence-container table tr td.fixed, .operators-presence-container table tr th.fixed {\n        position: absolute;\n        left: -120px;\n        width: 120px;\n        border-right: 1px solid #eee;\n    }\n    .operators-presence-container table tr td .operator-working-hours {\n        float: right;\n        margin-right: 5px;\n    }\n    .operators-presence-container table tr td:nth-child(even) {\n        background: #fafafa !important;\n    }\n    .operators-presence-container table tr td.selected {\n        background: #0099cc !important;\n    }\n    .operators-presence-container table tr:nth-child(2) td.selected {\n        background: #7FCAFF !important;\n    }\n    .operators-presence-container table tr:nth-child(3) td.selected {\n        background: #A77FFF !important;\n    }\n    .operators-presence-container table tr:nth-child(4) td.selected {\n        background: #7F97FF !important;\n    }\n    .operators-presence-container table tr:nth-child(5) td.selected {\n        background: #E77FFF !important;\n    }\n    .operators-presence-container table tr:nth-child(6) td.selected {\n        background: #FF7FB0 !important;\n    }\n    .operators-presence-container table tr:nth-child(7) td.selected {\n        background: #FF9C7E !important;\n    }\n    .operators-presence-container table tr:nth-child(8) td.selected {\n        background: #FFBD7E !important;\n    }\n    .operators-presence-container table tr:nth-child(9) td.selected {\n        background: #FFD77E !important;\n    }\n    .operators-presence-container table tr:nth-child(10) td.selected {\n        background: #FFF17E !important;\n    }\n    .operators-presence-container table tr:nth-child(11) td.selected {\n        background: #F3FF7E !important;\n    }\n    .operators-presence-container table tr:nth-child(12) td.selected {\n        background: #CAF562 !important;\n    }\n    .operators-presence-container table tr:nth-child(13) td.selected {\n        background: #62F5C8 !important;\n    }\n    .operators-presence-container table tr td.day-counts {\n        font-size: 12px;\n        text-align: center;\n        color: #0a0;\n        font-weight: 800;\n        min-width: 41px;\n    }\n    .operators-presence-container table tr td.warn {\n        color: #cc0000;\n    }\n    .operators-presence-container table tr td.warn2 {\n        color: #FF6E00;\n    }\n    .loading {\n        position: fixed;\n        top: 0;\n        left: 50%;\n        background: #0099cc;\n        color: white;\n        width: 160px;\n        height: 25px;\n        line-height: 24px;\n        text-align: center;\n        font-size: 12px;\n        margin-left: -100px;\n        border-radius: 0 0 4px 4px;\n    }\n\n    .day-buttons {\n        position: absolute;\n        top: 0;\n        right: -130px;\n    }\n    .day-buttons .btn {\n        width: 120px;\n        display: block;\n        margin: 5px 0;\n    }\n\n</style>\n\n<div ng-app=\"backofficeApp\" ng-controller=\"OperatorsPresenceCtrl\" class=\"operators-presence-container\">\n  <h1>Operator presence times</h1>\n\n  <div class=\"loading\" ng-show=\"loading\">Loading...</div>\n\n  <br>\n  <h5>\n    <a href=\"/review/operators_presence.csv?start={{ startWeekDate.format() }}\" target=\"_blank\" class=\"btn btn-default\">Recap</a>\n    <div ng-click=\"fetch()\" class=\"btn btn-default\">Refresh</div>\n    <div class=\"btn btn-default\" ng-click=\"previousWeek()\"><</div>\n    <div class=\"btn btn-default\" ng-click=\"nextWeek()\">></div>\n    Week {{ startWeekDate.format(\"w\") }} of {{ startWeekDate.format(\"YYYY\") }}: {{ startWeekDate.format(\"dddd D MMMM\") }} - {{ endWeekDate.format(\"dddd D MMMM\") }}\n  </h5>\n  <br>\n  <br>\n\n  <div class=\"table-container\" ng-repeat=\"weekday in [1, 2, 3, 4, 5, 6, 7]\">\n      <table class=\"table table-stripped\">\n        <tr>\n          <th class=\"fixed\">Times (Madagascar)</th>\n          <th class=\"hour\"\n              ng-class=\"(hour.clone().tz('Indian/Antananarivo').format('HH') == '06')?'main-of-day':''\"\n              ng-repeat=\"hour in getHours(weekday) track by $index\">\n            {{ (hour.clone().tz(\"Indian/Antananarivo\").format(\"HH\") == \"06\")?(hour.clone().tz(\"Indian/Antananarivo\").format(\"ddd HH\")):(hour.clone().tz(\"Indian/Antananarivo\").format(\"HH\")) }}h\n          </th>\n        </tr>\n        <tr ng-repeat=\"operator in operators track by $index\">\n          <td class=\"fixed\">\n            <span class=\"operator-name\">{{ operator.name }}</span>\n            <span class=\"operator-working-hours\">{{ operator.presences.length }}h</span>\n          </td>\n          <td ng-repeat=\"hour in getHours(weekday) track by $index\"\n              ng-mouseDown=\"initTogglePresences(operator, hour)\"\n              ng-mouseUp=\"endTogglePresences(operator, hour)\"\n              ng-class=\"(isOperatorPresent(operator, hour))?'selected':''\">\n          </td>\n        </tr>\n        <tr>\n          <td class=\"fixed\"></td>\n          <td class=\"day-counts\"\n              ng-repeat=\"hour in getHours(weekday) track by $index\"\n              ng-class=\"(countsForHour(hour) < countsToMatchForHour(hour))?'warn':((countsForHour(hour) > countsToMatchForHour(hour))?'warn2':'')\">\n            {{ countsForHour(hour) }} / {{ countsToMatchForHour(hour) }}\n          </td>\n        </tr>\n      </table>\n\n    <div class=\"day-buttons\">\n      <div class=\"btn btn-warning btn-xs\" ng-click=\"resetDay(weekday)\">Reset</div>\n      <div class=\"btn btn-warning btn-xs\" ng-click=\"copyDay(weekday, 1)\">Copy to next day</div>\n\n      <div class=\"btn btn-warning btn-xs\" ng-click=\"copyDay(weekday, 7)\">Copy to next week</div>\n    </div>\n  </div>\n</div>\n\n<div class=\"footer\">\n    <div class=\"copyright\">© Julie Desk 2015</div>\n</div>\n\n</body>\n</html>")
      end

      it 'should populate the correct instance variables' do
        get :index, start: Time.now

        expect(assigns(:operators).map(&:id)).to eq([@normal.id, @op1.id, @op2.id, @op3.id, @op4.id, @op5.id])
      end

      it 'should return the correct html if a start parameter is provided' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))


        get :index, start: DateTime.new(2015, 9, 10)
        expect(response.body).to eq("Semaine 37;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Thursday;Count\n#{@normal.name};;;;;;;;0\n#{@op1.name};13h - 14h;15h - 16h;;;;;;2\n#{@op2.name};;15h - 16h;;;;;;1\n#{@op3.name};;;;;;;;0\n#{@op4.name};;;;;;;;0\n#{@op5.name};;;;;;;;0\n")
      end

      it 'should render the correct json' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))


        get :index, start: DateTime.new(2015, 9, 10).to_s, format: :json
        expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"operators\":[{\"name\":\"#{@normal.name}\",\"id\":#{@normal.id},\"presences\":[]},{\"name\":\"#{@op1.name}\",\"id\":#{@op1.id},\"presences\":[\"20150910T100000\",\"20150911T120000\"]},{\"name\":\"#{@op2.name}\",\"id\":#{@op2.id},\"presences\":[\"20150911T120000\"]},{\"name\":\"#{@op3.name}\",\"id\":#{@op3.id},\"presences\":[]},{\"name\":\"#{@op4.name}\",\"id\":#{@op4.id},\"presences\":[]},{\"name\":\"#{@op5.name}\",\"id\":#{@op5.id},\"presences\":[]}]}}")
      end

      it 'should render the correct csv to be downloaded' do
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 10, 10, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 9, 11, 12, 00, 00))

        get :index, start: DateTime.new(2015, 9, 10).to_s, format: :csv
        expect(response.body).to eq("Semaine 37;Thursday;Friday;Saturday;Sunday;Monday;Tuesday;Wednesday;Thursday;Count\n#{@normal.name};;;;;;;;0\n#{@op1.name};13h - 14h;15h - 16h;;;;;;2\n#{@op2.name};;15h - 16h;;;;;;1\n#{@op3.name};;;;;;;;0\n#{@op4.name};;;;;;;;0\n#{@op5.name};;;;;;;;0\n")
      end
    end

    describe 'Add' do
      it 'should access the index page if the operator has admin privileges' do
        post :add, presences: []
        expect(response.body).to eq('{}')
      end

      it 'should not access the index page if the operator has not admin privileges' do
        @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user_non_admin,@pw)
        post :add
        expect(response).to redirect_to(root_path)
      end

      it 'should add a new operator presence' do
        expect(@op1.operator_presences.size).to eq(0)

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s]

        @op1.reload
        expect(@op1.operator_presences.size).to eq(4)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-10 00:00:00 UTC", "2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC"])
      end

      it 'should replace an existing presence if there is one on the same date' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12))
        expect(@op1.operator_presences.size).to eq(1)

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 10).to_s, DateTime.new(2015, 10, 12).to_s, DateTime.new(2015, 10, 13).to_s, DateTime.new(2015, 10, 14).to_s]

        @op1.reload
        expect(@op1.operator_presences.size).to eq(4)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-10 00:00:00 UTC", "2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC"])
      end

      it 'should add a new presence to the existing ones' do

        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 14))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 15))
        expect(@op1.operator_presences.size).to eq(4)

        post :add, operator_id: @op1, presences: [DateTime.new(2015, 10, 16).to_s]

        @op1.reload
        expect(@op1.operator_presences.size).to eq(5)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 00:00:00 UTC", "2015-10-13 00:00:00 UTC", "2015-10-14 00:00:00 UTC", "2015-10-15 00:00:00 UTC", "2015-10-16 00:00:00 UTC"])
      end
    end

    describe 'Copy Day' do

      it ' should raise the correct exception if no day is provided as parameter' do
        expect {
          post :copy_day
        }.to raise_error(RuntimeError, 'no day given')
      end

      it 'should copy the all the Operator Presences from a day to another one 3 days later' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(3)
        expect(@op2.operator_presences.size).to eq(3)

        post :copy_day, day: DateTime.new(2015, 10, 12, 17, 00, 00), days: 3

        expect(@op1.operator_presences.size).to eq(6)
        expect(@op2.operator_presences.size).to eq(6)

        @op1.reload
        @op2.reload
        expect(@op1.operator_presences.last(3).map{|op| op.date.to_s}).to eq(["2015-10-15 17:00:00 UTC", "2015-10-15 23:00:00 UTC", "2015-10-16 11:00:00 UTC"])
        expect(@op2.operator_presences.last(3).map{|op| op.date.to_s}).to eq(["2015-10-15 17:00:00 UTC", "2015-10-15 23:00:00 UTC", "2015-10-16 11:00:00 UTC"])
      end
    end

    describe 'Reset Day' do
      it ' should raise the correct exception if no day is provided as parameter' do
        expect {
          post :reset_day
        }.to raise_error(RuntimeError, 'no day given')
      end

      it 'should delete all the operators presences for a given day' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op2.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(4)
        expect(@op2.operator_presences.size).to eq(4)

        expect{
          post :reset_day, day: DateTime.new(2015, 10, 12, 17, 00, 00)
        }.to change{OperatorPresence.count}.by(-6)

        expect(@op1.operator_presences.size).to eq(1)
        expect(@op2.operator_presences.size).to eq(1)
      end
    end

    describe 'Remove' do
      it 'should remove the specified presences for the specified operator' do
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 16, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 17, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 12, 23, 00, 00))
        @op1.operator_presences.create(date: DateTime.new(2015, 10, 13, 11, 00, 00))

        expect(@op1.operator_presences.size).to eq(4)

        expect{
          post :remove, operator_id: @op1.id, presences: [DateTime.new(2015, 10, 12, 16, 00, 00).to_s, DateTime.new(2015, 10, 12, 23, 00, 00).to_s]
        }.to change{OperatorPresence.count}.by(-2)

        @op1.reload
        expect(@op1.operator_presences.size).to eq(2)
        expect(@op1.operator_presences.map{|op| op.date.to_s}).to eq(["2015-10-12 17:00:00 UTC", "2015-10-13 11:00:00 UTC"])
      end
    end
  end
end