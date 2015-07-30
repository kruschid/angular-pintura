# Folgender Algorithmus könnte die skalierung verbessern:
# http://stackoverflow.com/questions/13893966/constrained-proportional-scaling-in-kineticjs
$ = jQuery
###*
# Verwendet das Plugin "PanoramaViewer" um es um ein skalierbares Rechteck zu erweitern, 
# mit welchem der Aufnahmebereich für RecorderJobs definiert werden kann.
# Das Rechteck behält bei der Skalierung ein festes Seitenverhältnis bei 
# und kann dabei niemals so skaliert oder verschoben werden, das es sich
# ganz oder teilweise außerhalb des Bildes befindet.
#
# Extends plugin "PanoramaView" by adding scalable and movable rect.
# The rect represents the receptive area of a recorder job.
# The aspect ratio of rect is beeing kept by the algorithm.
# The algorithm also ensures that the rect can't be moved outside the image bounding box.
# @class RecorderJobCreator
###

# plugin name and namespace for plugin data
PN = 'RecorderJobCreator'

#define some events
events =
  ###*
  # Rect position/size was changed by user or event
  # @event MBC.RecorderJobCreator.events.RECT_CHANGED
  # @param {Object} rect contains positions of topLeft and bottomRight rect-corners
  # @param {Number} rect.x1 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.y1 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.x2 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.y2 relative coordinate, decimal in range(0,1)
  ###
  RECT_CHANGED: 'rectChanged'

  ###*
  # changes position/size of rect
  # @param {Object} rect contains positions of topLeft and bottomRight rect-corners
  # @param {Number} rect.x1 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.y1 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.x2 relative coordinate, decimal in range(0,1)
  # @param {Number} rect.y2 relative coordinate, decimal in range(0,1)
  ###
  CHANGE_RECT: 'changeRect'

# private Properties
p =
  ###*
  # @property stage
  # @type Kinetic.Stage
  ###
  stage: undefined
  
  ###*
  # contains image, overlayGroup and anchors
  # @property layer
  # @type Kinetic.Layer
  ###
  layer: undefined

  ###*
  # the panorma image, here with opacity of 50% 
  # @property image
  # @type Kinetic.Image
  ###
  image: undefined

  ###*
  # contains overlayImage and rect
  # group-clip capability is used to highlight the part of image, that is bounded by the rect
  # @property overlayGroup
  # @type Kinetic.Group
  ###
  overlayGroup: undefined

  ###*
  # panorama image with 100% opacity overlays the other panorama image. 
  # because of overlayGroup-clip function only rect-bounded part is shown. 
  # @property overlayImage
  # @type Kinetic.Image
  ###
  overlayImage: undefined

  ###*
  # scalable and movable rect to define receptive area
  # @property rect
  # @type Kinetic.Rect
  ###  
  rect: undefined

  ###*
  # anchors enable scaling and moving capabilities throug user interaction
  # @property anchors
  # @type Object
  ###    
  anchors:
    ###*
    # scaling rect by dragging top-left corner
    # @property anchors.topLeft
    # @type Kinetic.Circle
    ###    
    topLeft: undefined

    ###*
    # scaling rect by dragging bottom-right corner
    # @property anchors.bottomRight
    # @type Kinetic.Circle
    ###    
    bottomRight: undefined
    
    ###*
    # moving rect by dragging center corner
    # @property anchors.center
    # @type Kinetic.Circle
    ###    
    center: undefined

  ###*
  # radius of anchor
  # @property anchorRadius
  # @type Number
  ###    
  anchorRadius: 15

  ###*
  # stroke width
  # @property strokeWidth
  # @type Number
  ###    
  strokeWidth: 2

# public methods
m = 
  ###*
  # Performs event to functions binding
  # @method init
  # @return {Object} jQuery-Selector
  ###
  init: ->
    # copy default-Properties
    d = p
    # save properties for sharing with other methods
    @data PN, d
    # bind plugin events to functions
    @on(events.CHANGE_RECT, $.proxy(mm.onChangeRect, @))
    # bind PanoramaViewer events to functions
    pvEvents = MBC.PanoramaViewer.events
    @on(pvEvents.STAGE_READY, $.proxy(mm.onStageReady, @))
    @on(pvEvents.IMAGE_CHANGED, $.proxy(mm.onImageChanged, @))
    @on(pvEvents.SCALE_CHANGED, $.proxy(mm.onScaleChanged, @))
    @

#private methods
mm =
  ###*
  # adds references to stage, layer and image to plugin data
  # and runs init-methods for rect and anchors
  # Adds rect and overlayGroup to the layer 
  # @private
  # @method onStageReady
  ###
  onStageReady: (e) ->
    # get plugin data
    d = @data(PN)
    # remember reference to stage, layer and image
    [d.stage, d.layer, d.image] = [e.stage, e.layer, e.image]
    # save properties for sharing with other methods
    @data(PN, d)
    # init rect
    mm.initRectAndOverlay.apply(@)
    # init anchors
    mm.initAnchors.apply(@)
    # redraw layer
    d.layer.draw()

  ###*
  # Sets panorma image to 50% opacity and creates rect and overlayGroup
  # adds rect to overlayGroup and the latter to Layer
  # @private
  # @method initRect
  ###
  initRectAndOverlay: ->
    # get plugin data
    d = $(@).data(PN)  
    # show image with half opacity to highlight rect with full opacity 
    d.image.opacity(0.5)
    # define rect
    d.rect = new Kinetic.Rect
      x: d.stage.width()/4
      y: d.stage.height()/4
      width: d.stage.width()/4
      height: d.stage.height()/4
      stroke: 'white'
      strokeWidth: d.strokeWidth
      opacity: 0.5
    # define overlayGroup
    d.overlayGroup = new Kinetic.Group
      width: d.stage.width()
      height: d.stage.height()
      clip: 
        x: d.rect.x() 
        y: d.rect.y()
        width:  d.rect.width()
        height: d.rect.height()
    # add image to overlayGroup
    d.overlayImage = new Kinetic.Image()
    # add image and rect to overlayGroup
    d.overlayGroup.add(d.overlayImage).add(d.rect)
    # add overlayGroup to layer
    d.layer.add(d.overlayGroup)

  ###*
  # creates anchors, sets properties
  # binds drag-events to first dragBound function and then drag function
  # sets mouseover-icons
  # calls adjustAnchor function to place anchors to their corresponding positions
  # @private
  # @method initAnchors
  ###
  initAnchors: ->
    # get plugin data
    d = $(@).data PN  
    # top-left anchor
    anchorProperties =
      radius: d.anchorRadius
      stroke: '#666'
      fill: '#ddd'
      strokeWidth: d.strokeWidth
      opacity: 0.5
      draggable: true
      dragBoundFunc: $.proxy(mm.dragBoundFuncAnchor, @)
    # for each anchor
    for anchorName of d.anchors
      # assig clone of prototype
      d.anchors[anchorName] = new Kinetic.Circle(anchorProperties)
      # bind andjus anchros-function to each anchor
      d.anchors[anchorName].on('dragmove', $.proxy(mm.onDragAnchor, @))
      # mouseover: hover effect 
      d.anchors[anchorName].on 'mouseover', -> 
        @strokeWidth(@strokeWidth()*3)
        @opacity(0.75)
        d.layer.draw()
      # mouseout: default-mouse-cursor, default-stroke-width
      d.anchors[anchorName].on 'mouseout', ->
        document.body.style.cursor = 'default' 
        @strokeWidth(@strokeWidth()/3)
        @opacity(0.5)
        d.layer.draw()
      # add anchors to layer
      d.layer.add(d.anchors[anchorName])
    # set anchor offsets
    d.anchors.topLeft.on('mouseover',     -> document.body.style.cursor = 'nw-resize')
    d.anchors.bottomRight.on('mouseover', -> document.body.style.cursor = 'se-resize')
    d.anchors.center.on('mouseover',      -> document.body.style.cursor = 'move')
    # adjust position of anchors according to rect pos
    mm.adjustAnchors.apply(@)

  ###*
  # Keeps anchors within image
  # @private
  # @method dragBoundFuncAnchor
  # @param {Object} pos pointer position relative to canvas top-left-corner (x,y)
  # @param {Number} pos.x x-coordinate
  # @param {Number} pos.y y-coordinate
  # @return {Object} allowed position relative to canvas top-left-corner (x,y)
  ###
  dragBoundFuncAnchor: (pos) ->
    # get plugin data
    d = $(@).data PN
    # define imageBunds
    imageBounds =
      x1: d.image.getAbsolutePosition().x
      y1: d.image.getAbsolutePosition().y
      x2: d.image.getAbsolutePosition().x+d.image.width()*d.layer.scaleX()
      y2: d.image.getAbsolutePosition().y+d.image.height()*d.layer.scaleY()
    # make sure other anchors stay within image
    newPos =
      x: Math.min(Math.max(pos.x, imageBounds.x1), imageBounds.x2)
      y: Math.min(Math.max(pos.y, imageBounds.y1), imageBounds.y2)
    # return new pos
    newPos

  ###*
  # Moves and scales rect accoring the new positions of the anchors.
  # If center anchor is dragged function changes position of rect.
  # If topLeft anchor is dragged function changes position and scale of rect.
  # If bottomRight anchor is dragged function changes the rect scale.
  # The two anchors topLeft and bottomRight define a bounding area while the algorithm 
  # tries to scale the rect to cover a maximum of that bounding area regarding the rects
  # aspect ratio.
  # @private
  # @method onDragAnchor
  ###
  onDragAnchor: ->
    # get plugin data
    d = $(@).data PN
    # moving
    if d.anchors.center.isDragging()
      # img borders
      imgBounds =
        x1: d.image.x()
        y1: d.image.y()
        x2: d.image.x() + d.image.width()
        y2: d.image.y() + d.image.height()
      # keep rect within image
      d.rect.position
        x: Math.min(Math.max(imgBounds.x1, d.anchors.center.x()), imgBounds.x2-d.rect.width())
        y: Math.min(Math.max(imgBounds.y1, d.anchors.center.y()), imgBounds.y2-d.rect.height())
    # scaling by corner anchors (topLeft/bottomRight)
    else
      # define scaling bounds
      rectBounds =
        width:  d.anchors.bottomRight.x() - d.anchors.topLeft.x()
        height: d.anchors.bottomRight.y() - d.anchors.topLeft.y()
      # compute new size by width
      newRectSize =
        width: rectBounds.width
        height: d.rect.height()*(rectBounds.width/d.rect.width())
      # scale to cover whole rectBounds area
      if newRectSize.height > rectBounds.height
        newRectSize =
          width: d.rect.width()*(rectBounds.height/d.rect.height())
          height: rectBounds.height
      # leftTop anchor dragging
      if d.anchors.topLeft.isDragging()
        # move rect relative to fixed position of bottomRight anchor
        d.rect.position
          x: d.rect.x() + d.rect.width() - newRectSize.width
          y: d.rect.y() + d.rect.height() - newRectSize.height
      # now we dont need the old size anymore and can set the new one
      d.rect.size(newRectSize)
    # adjust anchors an overlayGroup according to new size and position of rect
    mm.adjustAnchors.apply(@)
    mm.adjustOverlay.apply(@)

  ###*
  # Positions anchors to their corresponding positions within rect
  # topLeft-anchor at the top-left corner of the rect
  # bottomRight-anchor at the bottom-right corner of the rect
  # center-anchor at the center point of the rect
  # @private
  # @method adjustAnchors
  ###
  adjustAnchors: ->
    # get plugin data
    d = $(@).data PN
    # adjust center-anchor
    d.anchors.center.offset
      x: d.rect.width()/-2
      y: d.rect.height()/-2
    .position
      x: d.rect.x()
      y: d.rect.y()
    # adjust top-anchor
    d.anchors.topLeft.position
      x: d.rect.x()
      y: d.rect.y() 
    # adjust right-anchor
    d.anchors.bottomRight.position
      x: d.rect.x()+d.rect.width() 
      y: d.rect.y()+d.rect.height() 

  ###*
  # sets position and size of overlayGroup according to position and size of the scalable and movable rect
  # @private
  # @method adjustAnchors
  ###
  adjustOverlay: ->
    # get plugin data
    d = $(@).data PN
    # adjust overlayGroup
    d.overlayGroup.clip
      x: d.rect.x()
      y: d.rect.y()
      width: d.rect.width()
      height: d.rect.height()

  ###*
  # replaces image in overlayGroup
  # @private
  # @method onImageChanged
  ###
  onImageChanged: ->
    # get plugin data
    d = $(@).data PN
    # set image
    d.overlayImage.setImage(d.image.getImage())
    # set size of image
    d.overlayImage.size
      width: d.image.width()
      height: d.image.height()

  ###*
  #
  ###
  onScaleChanged: (e) ->
    # get plugin data
    d = $(@).data PN
    d.rect.strokeWidth(d.strokeWidth/e.newScale)
    for i,a of d.anchors
      a.radius(d.anchorRadius/e.newScale)
      a.strokeWidth(d.strokeWidth/e.newScale)
# create new plugin
MBC.registerJQueryPlugin PN, m