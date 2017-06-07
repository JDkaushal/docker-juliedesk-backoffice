angular.module('commonDirectives').directive('constraintTile', function () {
    function link(scope, element, attr) {
        var constraintTileData = scope[attr['constraintTileData']];

        new ConstraintTile(
            $(element),
            {
                data: constraintTileData,
                readOnly: true
            }
        );
    }

    return {
        restrict: 'A',
        link: link
    }
});