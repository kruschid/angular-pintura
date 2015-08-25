(function() {
  var NGPCanvas, NGPImage, NGPImageLoader, NGPIndicator, module,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module = angular.module('ngPintura', []);

  NGPImageLoader = (function() {
    function NGPImageLoader(files, loadedCb, progressCb) {
      var file, _i, _len, _ref;
      this.files = files != null ? files : [];
      this.loadedCb = loadedCb;
      this.progressCb = progressCb;
      this.onload = __bind(this.onload, this);
      this.loaded = 0;
      _ref = this.files;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        file.image = new Image();
        file.image.onload = this.onload;
        file.image.src = file.url;
      }
    }

    NGPImageLoader.prototype.onload = function() {
      this.loaded += 1;
      if (this.progressCb) {
        this.progressCb(this.loaded / this.files.length);
      }
      if (this.loaded >= this.files.length) {
        return this.loadedCb(this.files);
      }
    };

    return NGPImageLoader;

  })();

  NGPCanvas = (function() {
    function NGPCanvas() {
      var imageNode, indicatorNode, layerNode, stageNode;
      stageNode = new Konva.Stage({
        container: angular.element('<div>')[0]
      });
      layerNode = new Konva.Layer();
      imageNode = new Konva.Image();
      indicatorNode = new Konva.Rect();
      stageNode.add(layerNode);
      layerNode.add(imageNode);
      layerNode.add(indicatorNode);
      this.progressCb = void 0;
      this.stage = stageNode;
      this.layer = layerNode;
      this.image = new NGPImage(imageNode);
      this.indicator = new NGPIndicator(indicatorNode);
    }

    NGPCanvas.prototype.resize = function(width, height) {
      this.stage.size({
        width: width,
        height: height
      });
      this.indicator.node.position({
        x: width / 2,
        y: height / 2
      });
      return this.image.adjustScaleBounds(this.stage.size());
    };

    NGPCanvas.prototype.imageChange = function(src) {
      this.image.node.visible(false);
      this.indicator.node.visible(true);
      this.indicator.animation.start();
      if (typeof src === 'string') {
        return Konva.Image.fromURL(src, (function(_this) {
          return function(newImage) {
            _this.setImage(newImage.image());
            return newImage.destroy();
          };
        })(this));
      } else if (src instanceof Image) {
        return this.setImage(src);
      } else if (src instanceof Array) {
        return this.setCollage(src);
      } else {
        return console.log('src is empty or unknown format:', src);
      }
    };

    NGPCanvas.prototype.setImage = function(newImage) {
      this.image.node.size({
        width: newImage.width,
        height: newImage.height
      });
      this.image.node.image(newImage);
      this.indicator.node.visible(false);
      this.indicator.animation.stop();
      this.image.adjustScaleBounds(this.stage.size());
      this.image.node.visible(true);
      this.image.node.parent.draw();
      return this.image.node.fire(this.image.LOADED);
    };

    NGPCanvas.prototype.setCollage = function(files) {
      var loaded;
      loaded = (function(_this) {
        return function(images) {
          var image, rowsX, rowsY, tmpLayer, _i, _len;
          rowsX = 0;
          rowsY = 0;
          tmpLayer = new Konva.Layer();
          for (_i = 0, _len = images.length; _i < _len; _i++) {
            image = images[_i];
            rowsX = Math.max(image.x + 1, rowsX);
            rowsY = Math.max(image.y + 1, rowsY);
            tmpLayer.add(new Konva.Image({
              image: image.image,
              x: image.x * image.image.width,
              y: image.y * image.image.height
            }));
          }
          return tmpLayer.toImage({
            x: 0,
            y: 0,
            width: rowsX * images[0].image.width,
            height: rowsY * images[0].image.height,
            callback: function(image) {
              _this.setImage(image);
              return tmpLayer.destroy();
            }
          });
        };
      })(this);
      return new NGPImageLoader(files, loaded, this.progressCb);
    };

    return NGPCanvas;

  })();


  /*
   *
   */

  NGPIndicator = (function() {
    function NGPIndicator(node) {
      var _animFn;
      this.node = node;
      this.rotationSpeed = 270;
      this.node.setAttrs({
        width: 50,
        height: 50,
        fill: 'pink',
        stroke: 'white',
        strokeWidth: 4,
        zIndex: 99,
        visible: false,
        offset: {
          x: 25,
          y: 25
        }
      });
      _animFn = (function(_this) {
        return function(frame) {
          var angleDiff;
          angleDiff = frame.timeDiff * _this.rotationSpeed / 1000;
          return _this.node.rotate(angleDiff);
        };
      })(this);
      this.animation = new Konva.Animation(_animFn, this.node.parent);
    }

    return NGPIndicator;

  })();


  /*
   *
   */

  NGPImage = (function() {
    function NGPImage(node) {
      this.node = node;
      this.LOADED = 'loaded';
      this.node.draggable(true);
      this.minScale = 0.5;
      this.maxScale = 1;
      this.tween = void 0;
      this.tweenDuration = 0.25;
    }

    NGPImage.prototype.adjustScaleBounds = function(viewport) {
      if (!this.node.width() || !this.node.height()) {
        return;
      }
      this.minScale = viewport.width / this.node.width();
      if (viewport.height < this.node.height() * this.minScale) {
        this.minScale = viewport.height / this.node.height();
      }
      return this.minScale = Math.min(this.minScale, 1);
    };

    NGPImage.prototype._fitScale = function(scale) {
      return Math.min(Math.max(scale, this.minScale), this.maxScale);
    };

    NGPImage.prototype._zoomToPointAttrs = function(scale, point) {
      var attrs, imgPoint, scaling;
      scaling = this.node.scaleX() + scale;
      scaling = this._fitScale(scaling);
      imgPoint = this.node.getAbsoluteTransform().copy().invert().point(point);
      return attrs = {
        x: (-imgPoint.x + point.x / scaling) * scaling,
        y: (-imgPoint.y + point.y / scaling) * scaling,
        scaleX: scaling,
        scaleY: scaling
      };
    };

    NGPImage.prototype.zoomToPoint = function(scale, point) {
      this.node.setAttrs(this._zoomToPointAttrs(scale, point));
      return this.node.parent.draw();
    };

    NGPImage.prototype.zoomToPointer = function(scale) {
      return this.zoomToPoint(scale, this.node.getStage().getPointerPosition());
    };

    NGPImage.prototype._stageCenter = function() {
      var center;
      return center = {
        x: this.node.getStage().width() / 2,
        y: this.node.getStage().height() / 2
      };
    };

    NGPImage.prototype.zoomToCenter = function(scale) {
      return this.zoomToPoint(scale, this._stageCenter());
    };

    NGPImage.prototype.zoomToPointTween = function(scale, point, callback) {
      var tweenAttrs;
      tweenAttrs = this._zoomToPointAttrs(scale, point);
      if (scale !== this.node.scaleX() || tweenAttrs.x !== this.node.x() || tweenAttrs.y !== this.node.y()) {
        if (this.tween) {
          this.tween.pause().destroy();
        }
        this.tween = new Konva.Tween(angular.extend(tweenAttrs, {
          node: this.node,
          duration: this.tweenDuration,
          easing: Konva.Easings.EaseOut,
          onFinish: callback
        }));
        return this.tween.play();
      }
    };

    NGPImage.prototype.zoomToCenterTween = function(scale, callback) {
      return this.zoomToPointTween(scale, this._stageCenter(), callback);
    };

    NGPImage.prototype.moveByVectorTween = function(v, callback) {
      var pos;
      pos = this.node.position();
      if (v.x) {
        pos.x += v.x;
      }
      if (v.y) {
        pos.y += v.y;
      }
      if (pos.x !== this.node.x() || pos.y !== this.node.y()) {
        if (this.tween) {
          this.tween.pause().destroy();
        }
        this.tween = new Konva.Tween(angular.extend(pos, {
          node: this.node,
          duration: this.tweenDuration,
          easing: Konva.Easings.EaseOut,
          onFinish: callback
        }));
        return this.tween.play();
      }
    };

    NGPImage.prototype.fitInViewTween = function(callback) {
      var attrs, imgScaled;
      imgScaled = {
        width: this.node.width() * this.minScale,
        height: this.node.height() * this.minScale
      };
      attrs = {
        scaleX: this.minScale,
        scaleY: this.minScale,
        x: imgScaled.width < this.node.getStage().width() ? (this.node.getStage().width() - imgScaled.width) / 2 : 0,
        y: imgScaled.height < this.node.getStage().height() ? (this.node.getStage().height() - imgScaled.height) / 2 : 0
      };
      if (attrs.x !== this.node.x() || attrs.y !== this.node.y() || attrs.scaleX !== this.node.scaleX()) {
        if (this.tween) {
          this.tween.pause().destroy();
        }
        this.tween = new Konva.Tween(angular.extend(attrs, {
          node: this.node,
          duration: this.tweenDuration,
          easing: Konva.Easings.EaseOut,
          onFinish: callback
        }));
        return this.tween.play();
      }
    };

    return NGPImage;

  })();

  module.service('ngPintura', function() {
    return new NGPCanvas();
  });


  /**
   * pintura container
   * creates and shares paperjs scope with child directives
   * creates canvas
   */

  module.directive('ngPintura', ["ngPintura", "$window", function(ngPintura, $window) {
    var directive;
    return directive = {
      transclude: true,
      scope: {
        src: '=ngpSrc',
        scaling: '=ngpScaling',
        position: '=ngpPosition',
        fitOnload: '=ngpfitOnload',
        maxScaling: '=ngpMaxScaling',
        scaleStep: '=ngpScaleStep',
        mwScaleStep: '=ngpMwScaleStep',
        moveStep: '=ngpMoveStep',
        progress: '=ngpProgress'
      },
      link: function(scope, element, attrs, ctrl, transcludeFn) {
        var applySyncScope, imageChange, imageLoad, maxScalingChange, mouseWheel, positionChange, resizeContainer, scalingChange, setScalingDisabled, syncScope;
        scope.slider = {
          value: void 0,
          fromScaling: function(scale) {
            return this.value = parseInt(((scale - ngPintura.image.minScale) / (ngPintura.image.maxScale - ngPintura.image.minScale)) * 100);
          },
          toScaling: function() {
            return (ngPintura.image.maxScale - ngPintura.image.minScale) * (this.value / 100) + ngPintura.image.minScale;
          }
        };
        resizeContainer = function() {
          ngPintura.resize(element[0].clientWidth, element[0].clientHeight);
          return setScalingDisabled();
        };
        imageChange = function() {
          return ngPintura.imageChange(scope.src);
        };
        positionChange = function() {
          var _ref, _ref1;
          if (((_ref = scope.position) != null ? _ref.x : void 0) && ((_ref1 = scope.position) != null ? _ref1.y : void 0)) {
            ngPintura.image.node.position(scope.position);
            return ngPintura.layer.draw();
          }
        };
        scalingChange = function() {
          ngPintura.image.node.scale({
            x: scope.scaling,
            y: scope.scaling
          });
          ngPintura.layer.draw();
          return scope.slider.fromScaling(scope.scaling);
        };
        mouseWheel = function(e) {
          e.evt.preventDefault();
          if (e.evt.wheelDeltaY > 0) {
            ngPintura.image.zoomToPointer(scope.mwScaleStep);
          } else {
            ngPintura.image.zoomToPointer(-scope.mwScaleStep);
          }
          return applySyncScope();
        };
        syncScope = function() {
          scope.position = ngPintura.image.node.position();
          scope.scaling = ngPintura.image.node.scaleX();
          if (scope.slider.toScaling() !== scope.scaling) {
            return scope.slider.fromScaling(scope.scaling);
          }
        };
        applySyncScope = function() {
          return scope.$apply(syncScope);
        };
        scope.fitInView = function() {
          return ngPintura.image.fitInViewTween(applySyncScope);
        };
        scope.moveUp = function() {
          return ngPintura.image.moveByVectorTween({
            y: scope.moveStep
          }, applySyncScope);
        };
        scope.moveDown = function() {
          return ngPintura.image.moveByVectorTween({
            y: -scope.moveStep
          }, applySyncScope);
        };
        scope.moveRight = function() {
          return ngPintura.image.moveByVectorTween({
            x: -scope.moveStep
          }, applySyncScope);
        };
        scope.moveLeft = function() {
          return ngPintura.image.moveByVectorTween({
            x: scope.moveStep
          }, applySyncScope);
        };
        scope.zoomIn = function() {
          return ngPintura.image.zoomToCenterTween(scope.scaleStep, applySyncScope);
        };
        scope.zoomOut = function() {
          return ngPintura.image.zoomToCenterTween(-scope.scaleStep, applySyncScope);
        };
        scope.sliderChange = function() {
          var scale;
          scale = scope.slider.toScaling() - ngPintura.image.node.scaleX();
          ngPintura.image.zoomToCenter(scale);
          return syncScope();
        };
        setScalingDisabled = function() {
          return scope.scalingDisabled = ngPintura.image.minScale >= ngPintura.image.maxScale;
        };
        imageLoad = function() {
          if (scope.fitOnload) {
            scope.fitInView();
          }
          return setScalingDisabled();
        };
        maxScalingChange = function() {
          ngPintura.image.maxScale = scope.maxScaling;
          return setScalingDisabled();
        };
        ngPintura.progressCb = function(progress) {
          return scope.$apply(function() {
            return scope.progress = progress;
          });
        };
        if (scope.maxScaling == null) {
          scope.maxScaling = 1;
        }
        if (scope.scaleStep == null) {
          scope.scaleStep = 0.4;
        }
        if (scope.mwScaleStep == null) {
          scope.mwScaleStep = 0.1;
        }
        if (scope.moveStep == null) {
          scope.moveStep = 100;
        }
        if (scope.fitOnload == null) {
          scope.fitOnload = true;
        }
        element.append(ngPintura.stage.content);
        resizeContainer();
        angular.element($window).on('resize', resizeContainer);
        scope.$watch('src', imageChange);
        scope.$watch('position', positionChange, true);
        scope.$watch('scaling', scalingChange);
        scope.$watch('maxScaling', maxScalingChange);
        ngPintura.image.node.on('dragend', applySyncScope);
        ngPintura.image.node.on('mousewheel', mouseWheel);
        ngPintura.image.node.on(ngPintura.image.LOADED, imageLoad);
        return transcludeFn(scope, function(clonedTranscludedTemplate) {
          return element.append(clonedTranscludedTemplate);
        });
      }
    };
  }]);

}).call(this);
