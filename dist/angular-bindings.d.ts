/// <reference types="angular" />
import * as angular from 'angular';
import * as Konva from 'konva';
export interface IPinturaConfig {
    src?: string;
    relativeScale?: number;
    scale?: number;
    position?: {
        x: number;
        y: number;
    };
    fitOnload?: boolean;
    maxScale?: number;
    scaleStep?: number;
    mwScaleStep?: number;
    showIndicator?: number;
    moveStep?: number;
    progress?: number;
    hotspots?: Konva.Shape[];
    showHotspots?: boolean;
}
export declare const KDPintura: angular.IModule;
