import * as angular from 'angular';
import * as KDP from './konva-pintura';
const directive = angular.module('kdPintura', []);
directive.directive('kdPintura', ($window) => ({
    transclude: true,
    scope: {
        config: '=kdpConfig'
    },
    link: (scope, element, attrs, ctrl, transcludeFn) => {
        const config = scope.config ? scope.config : {};
        const state = new KDP.State(syncConfig);
        element.append(state.stage.container());
        transcludeFn(scope, (transcludedTemplate) => element.append(transcludedTemplate));
        function syncConfig(state) {
            console.log('syncConfig');
            scope.$apply(() => {
                config.relativeScale = KDP.toRelativeScale(state);
                config.scale = state.rootLayer.scaleX();
            });
        }
        function onResize() {
            KDP.resize(state, {
                width: element[0].clientWidth,
                height: element[0].clientHeight
            });
        }
        function changeImage() {
            if (config.src)
                KDP.changeImage(state, config.src);
            else
                console.log('angular-pintura: src should be a url');
        }
        function changeRealtiveScale(relativeScale) {
            if (typeof relativeScale === 'number')
                KDP.zoomToCenter(state, relativeScale);
        }
        function changeHotspots() {
            if (config.hotspots)
                state.hotspotsGroup.removeChildren();
            state.hotspotsGroup.add.apply(state.hotspotsGroup, config.hotspots);
        }
        function changeHotspotsVisbility() {
            state.hotspotsGroup.visible(config.showHotspots);
            state.stage.draw();
        }
        scope.fitInView = () => KDP.fitInView(state);
        scope.zoomIn = () => KDP.zoomIn(state);
        scope.zoomOut = () => KDP.zoomOut(state);
        scope.$watch('config.src', changeImage);
        scope.$watch('config.relativeScale', changeRealtiveScale);
        scope.$watch('config.hotspots', changeHotspots);
        scope.$watch('config.showHotspots', changeHotspotsVisbility);
        onResize();
    }
}));
export const KDPintura = directive;
