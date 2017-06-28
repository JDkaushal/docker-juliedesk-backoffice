(function () {

    var app = angular.module('date-suggestions-full-auto-review-manager-controllers', ['angularMoment', 'commonDirectives', 'commonServices', 'commonPipes']);

    app.controller("date-suggestions-full-auto-review-list-controller", ['$scope', 'moment', '$http', 'conscienceApi', function ($scope, moment, $http, conscienceApi) {
        $scope.now = moment();
        $scope.start = $scope.now.clone().startOf('isoWeek');

        $scope.previousWeekStart = function() {
            return $scope.start.clone().add(-7, 'd');
        };

        $scope.nextWeekStart = function() {
            return $scope.start.clone().add(7, 'd').startOf('isoWeek');
        };
        $scope.shouldShowNextWeek = function() {
            return $scope.end() < $scope.now.clone();
        };

        $scope.goToWeek = function(mDate) {
            $scope.start = mDate;
            $scope.fetch();
        };

        $scope.end = function(mDate) {
            if(!mDate) {
                mDate = $scope.start;
            }
            var end = mDate.clone().endOf("isoWeek");
            return end > $scope.now ? $scope.now : end;
        };

        $scope.openLink = function(dateSuggestionsReview) {
            window.open("/review/date_suggestions_reviews/" + dateSuggestionsReview.id + "/full_auto");
        };




        $scope.fetch = function() {
            $scope.loading = true;
            $http.get("/review/date_suggestions_reviews/full_auto", {
                    params: {
                        start: $scope.start.format(),
                        end: $scope.end().format()
                    },
                    headers: {'Accept': 'application/json'}
                }
            ).then(function (response) {
                $scope.totalCount = response.data.data.total_count;
                $scope.julieActions = response.data.data.julie_actions;

                $scope.loading = false;
            });
        };

        $scope.fetch();
    }]);

})();