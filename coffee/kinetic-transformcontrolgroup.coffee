###*
# Eine Ableitung der Klasse Kinetic.Group.
# Erzeugt eine Gruppe mit einem Rechteck und Ankerpunkten
# Beinhaltet Methoden, die das Skalieren, Bewegen und Rotieren des Rechtecks 
# durch das Ziehen entsprechende Ankerpunkte ermöglichen.
# @class Kinetic.MBCTransformControlGroup
# @extends Kinetic.Group
###
class Kinetic.MBCTransformControlGroup extends Kinetic.Group
  ###*
  # Notifies listeners about changed position & size of rect
  # We define this custom event type because we want notify about
  # new position and scale simultaneusly by one event.
  # Kinetic has for each of the attributes x,y,width,height its own
  # event type.
  # @event Kinetic.MBCTransformControlGroup::TRANSFORMRECT_CHANGE
  # @param {Event} e Event object
  # @param {String} e.newVal New Position (x/y)
  # @param {String} e.oldVal Old Position (x/y)
  ###
  TRANSFORMRECT_CHANGE: 'transformRectAttributesChange'

  ###*
  # Notifies listeners about changed scale of transform controls (anchors scale)
  # @event Kinetic.MBCTransformControlGroup::ANCHORSCALE_CHANGE
  # @param {Event} e Event object
  # @param {Number} e.newVal New scale value
  # @param {Number} e.oldVal Old scale value
  ###
  ANCHORSCALE_CHANGE: 'anchorScaleChange'

  ###*
  # Notifies listeners about changed drag bounds
  # it may be that current control-rect is outside the new drag bounds
  # @event Kinetic.MBCTransformControlGroup::DRAGBOUNDS_CHANGE
  # @param {Event} e Event object
  # @param {Number} e.newVal New drag Bounds (x/y & width/height)
  # @param {Number} e.oldVal Old drag Bounds (x/y & width/height)
  ###
  DRAGBOUNDS_CHANGE: 'dragBoundsChange'
  
  ###*
  # Initialisiert bzw. deklariert properties
  # Ruft anschließend {{crossLink "____init:method"}}{{/crossLink}} auf
  # @method constructor
  # @contructor
  # @param {Object} o
  # @param {Number} [o.rotateAnchorRectDistance=20] Distance between rect and rotation anchor: {{#crossLink "_rotateAnchorRectDistance:attribute"}}{{/crossLink}}
  # @param {String} [o.rectStroke='white']          Color of rect outline: {{#crossLink "_rectStroke:attribute"}}{{/crossLink}}
  # @param {String} [o.anchorStroke='#666']         Color of anchors outline: {{#crossLink "_anchorStroke:attribute"}}{{/crossLink}}
  # @param {String} [o.anchorFill='#ddd']           Fill color of anchor: {{#crossLink "_anchorFill:attribute"}}{{/crossLink}}
  # @param {Number} [o.anchorRadius=15]             Anchor radius {{#crossLink "_anchorRadius:attribute"}}{{/crossLink}}
  # @param {Number} [o.strokeWidth=2]               Stroke width {{#crossLink "_strokeWidth:attribute"}}{{/crossLink}}
  # @return {Kinetic.MBCTransformControlGroup}
  ###
  constructor: (o) ->
    ###*
    # enables rotation if true
    # @private
    # @property _rotatable
    # @default false
    # @type Boolean
    ### 
    @_rotatable = if o?.rotatable then true else false

    ###*
    # distance between rotate anchor and rect
    # @private
    # @property _rotateAnchorRectDistance
    # @default 20
    # @type Number
    ###    
    @_rotateAnchorRectDistance = if o?.rotateAnchorRectDistance then o.rotateAnchorRectDistance else 20  

    ###*
    # rect stroke color
    # @private
    # @property _rectStroke
    # @type String
    ###  
    @_rectStroke = if o?.rectStroke then o.rectStroke else 'white'

    ###*
    # anchor stroke color
    # @private
    # @property _anchorStroke
    # @type String
    ### 
    @_anchorStroke = if o?.anchorStroke then o.anchorStroke else '#666'

    ###*
    # anchor color
    # @private
    # @property _anchorFill
    # @type String
    ### 
    @_anchorFill = if o?.anchorFill then o.anchorFill else '#ddd'

    ###*
    # radius of anchor
    # @private
    # @property _anchorRadius
    # @type Number
    ###    
    @_anchorRadius = if o?.anchorRadius then o.anchorRadius else 15

    ###*
    # stroke width
    # @private
    # @property _strokeWidth
    # @type Number
    ###    
    @_strokeWidth = if o?.strokeWidth then o.strokeWidth else 2

    ###*
    # scalable and movable rect to define receptive area
    # @private
    # @property _rect
    # @type Kinetic.Rect
    ###  
    @_rect = undefined

    ###*
    # line between rotate anchor and rect
    # @private
    # @property _rotateAnchorLine
    # @type Kinetic.Line
    ###    
    @_rotateAnchorLine = undefined

    ###*
    # Anchors enable scaling rotating and moving capabilities
    # @private
    # @property _anchors
    # @type Object
    ###    
    @_anchors =
      ###*
      # scaling rect by dragging top-left corner
      # @private
      # @property _anchors.topLeft
      # @type Kinetic.Circle
      ###    
      topLeft: undefined

      ###*
      # scaling rect by dragging top-right corner
      # @private
      # @property _anchors.topRight
      # @type Kinetic.Circle
      ###    
      topRight: undefined

      ###*
      # scaling rect by dragging bottom-right corner
      # @private
      # @property _anchors.bottomRight
      # @type Kinetic.Circle
      ###    
      bottomRight: undefined
      
      ###*
      # scaling rect by dragging bottom corner
      # @private
      # @property _anchors.bottomLeft
      # @type Kinetic.Circle
      ###    
      bottomLeft: undefined

      ###*
      # moving rect by dragging center corner
      # @private
      # @property _anchors.center
      # @type Kinetic.Circle
      ###    
      center: undefined

      ###*
      # rotate rect by dragging bottom-right corner
      # @private
      # @property _anchors.rotate
      # @type Kinetic.Circle
      ###    
      rotate: undefined
    
    # call super contructor
    super(o)
    # define classname
    @className = 'MBCTransformControlGroup'
    # run initialization process
    return @____init()

  ###*
  # Init-Method
  # runs methods to create rect and anchors
  # binds events
  # @private
  # @method ____init
  # @return Kinetic.MBCTransformControlGroup
  ###
  ____init: ->
    # create anchors and rect
    @_createRect()
    @_createAnchors()
    # bind events
    @on(@ANCHORSCALE_CHANGE, => @_adjustTransformConrols())
    @on(@TRANSFORMRECT_CHANGE, (e) => @_transformRectAttributesChange(e))
    @on(@DRAGBOUNDS_CHANGE, => @_dragBoundsChange())
    # return current instance
    return @
 
  ###*
  # Creates rect and line between anchor and rotation anchor
  # Adds these to parent group (super class)
  # @private
  # @method _createRect
  ###
  _createRect: ->
    # create and add rect to transform group
    @_rect = new Kinetic.Rect
      x: 0
      y: 0
      width: 50
      height: 50 
      stroke: @_rectStroke
      strokeWidth: @_strokeWidth
    @add(@_rect)
    # add line between rect and rotate anchor
    @_rotateAnchorLine = new Kinetic.Line
      visible: @_rotatable
      stroke: 'white'
      strokeWidth: @_strokeWidth
    @add(@_rotateAnchorLine)
    # sync rect position and scale
    @setTransformRectAttributes
      size: @_rect.size()
      position: @_rect.position()

  ###*
  # Creates anchors and adds these to group
  # adds dragBoundFunc to each anchor: {{crossLink "_dragBoundFunc:method"}}{{/crossLink}}
  # binds drag event to each anchor: {{crossLink "_onDragAnchor:method"}}{{/crossLink}
  # sets anchor-mouseover-icons
  # calls adjustAnchor function to place anchors to their corresponding positions
  # @private
  # @method _createAnchors
  ###
  _createAnchors: ->
    # generic anchor
    anchorProperties =
      radius: @_anchorRadius
      stroke: @_anchorStroke
      fill: @_anchorFill
      strokeWidth: @_strokeWidth
      draggable: true
      dragBoundFunc: (pos) => @_dragBoundFunc(pos)
    # for each anchor
    for anchorName of @_anchors
      # assig clone of prototype
      anchor = new Kinetic.Circle(anchorProperties)
      # bind andjus anchros-function to each anchor
      anchor.on('dragmove', => @_onDragAnchor())
      # mouseover: hover effect 
      anchor.on 'mouseover', -> 
        @strokeWidth(@strokeWidth()*3)
        @getParent().draw()
      # mouseout: default-mouse-cursor, default-stroke-width
      anchor.on 'mouseout', ->
        document.body.style.cursor = 'default' 
        @strokeWidth(@strokeWidth()/3)
        @getParent().draw()
      # add anchors to layer
      @add(anchor)
      # add to properties
      @_anchors[anchorName] = anchor
    # visibility of rotate anchor
    @_anchors.rotate.visible(@_rotatable)
    # set anchor icons
    @_anchors.topLeft.on('mouseover', -> document.body.style.cursor = 'nw-resize')
    @_anchors.bottomRight.on('mouseover', -> document.body.style.cursor = 'se-resize')
    @_anchors.topRight.on('mouseover', -> document.body.style.cursor = 'ne-resize')
    @_anchors.bottomLeft.on('mouseover', -> document.body.style.cursor = 'sw-resize')
    @_anchors.center.on('mouseover', -> document.body.style.cursor = 'move')
    @_anchors.rotate.on('mouseover', -> document.body.style.cursor = 'crosshair')
    # adjust position of anchors according to rect pos
    @_adjustTransformConrols()

  ###*
  # Event listener for transform rect attributes (width/height & x/y)
  # @private
  # @param {Object} e See {{#crossLink "TRANSFORMRECT_CHANGE:event"}}{{/crossLink}}
  # @method dragBoundFuncAnchor
  ###
  _transformRectAttributesChange: (e) ->
    @_rect.position(e.newVal.position)
    @_rect.size(e.newVal.size)
    # adjust anchors an overlayGroup according to new size and position of rect
    @_adjustTransformConrols()
    # redraw canvas
    @getStage().draw()

  ###*
  # keeps rect within drag bounds
  # @private
  # @method _dragBoundsChange
  ###
  _dragBoundsChange: ->
    if @getDragBounds()
      @_rect.position
        x: Math.max(@_rect.x(), @getDragBounds().x)
        y: Math.max(@_rect.y(), @getDragBounds().y)
      .size
        width:  Math.min(@_rect.width(),  @getDragBounds().width  - @_rect.x())
        height: Math.min(@_rect.height(), @getDragBounds().height - @_rect.y())
      # notify listeners about changed attributes
      @setTransformRectAttributes
        size: @_rect.size()
        position: @_rect.position()
      # adjust anchors
      @_adjustTransformConrols()

  ###*
  # Keeps anchors within drag bounds
  # @private
  # @method dragBoundFuncAnchor
  # @param {Object} absPos Absolute pointer position relative to canvas top-left-corner (x,y)
  # @param {Number} absPos.x x-coordinate
  # @param {Number} absPos.y y-coordinate
  # @return {Object} Final absolute position relative to canvas top-left-corner (x,y)
  ###
  _dragBoundFunc: (absPos) ->
    #
    # (1) translate absolute position to local pos
    #
    pos = @getAbsoluteTransform().copy().invert().point(absPos)
    #
    # (2) universal drag bounds
    #
    if @getDragBounds()
      dragBounds =
        x1: @getDragBounds().x
        y1: @getDragBounds().y
        x2: @getDragBounds().x + @getDragBounds().width
        y2: @getDragBounds().y + @getDragBounds().height
      # center anchor
      if @_anchors.center.isDragging()
        dragBounds =
          x1: dragBounds.x1 + @_rect.width()/2
          y1: dragBounds.y1 + @_rect.height()/2
          x2: dragBounds.x2 - @_rect.width()/2
          y2: dragBounds.y2 - @_rect.height()/2
      # keep pos within bounds
      pos =
        x: Math.min(Math.max(pos.x, dragBounds.x1), dragBounds.x2)
        y: Math.min(Math.max(pos.y, dragBounds.y1), dragBounds.y2)
    #
    # (3) regard min size
    #
    if @getMinSize()
      # top-left anchor
      if @_anchors.topLeft.isDragging()
        pos = 
          x: Math.min(pos.x, @_anchors.topRight.x()   - @getMinSize().width)
          y: Math.min(pos.y, @_anchors.bottomLeft.y() - @getMinSize().height)
      # top-right anchor
      else if @_anchors.topRight.isDragging()
        pos = 
          x: Math.max(pos.x, @_anchors.topLeft.x()     + @getMinSize().width)
          y: Math.min(pos.y, @_anchors.bottomRight.y() - @getMinSize().height)
      # bottom-right anchor
      else if @_anchors.bottomRight.isDragging()
        pos =
          x: Math.max(pos.x, @_anchors.bottomLeft.x() + @getMinSize().width)
          y: Math.max(pos.y, @_anchors.topRight.y()   + @getMinSize().height)
      # bottom-left anchor
      else if @_anchors.bottomLeft.isDragging()
        pos =
          x: Math.min(pos.x, @_anchors.bottomRight.x() - @getMinSize().width)
          y: Math.max(pos.y, @_anchors.topRight.y()    + @getMinSize().height)
    #
    # (4) translate position back to absoulte coordinates
    #
    absPos = @getAbsoluteTransform().copy().point(pos)
    # return result
    return absPos

  ###*
  # Moves and scales rect accoring the new positions of the anchors.
  # regards minSize setted for the rect (assumes that minSize is setted)
  # @private
  # @method _onDragAnchor
  ###
  _onDragAnchor: ->
    # moving
    if @_anchors.center.isDragging()
      # keep rect within boundaries
      @_rect.position
        x: @_anchors.center.x() - @_rect.width()/2
        y: @_anchors.center.y() - @_rect.height()/2
    # scaling by topLeft anchor
    else if @_anchors.topLeft.isDragging()
      @_rect.position(@_anchors.topLeft.position())
      .size
        width:  @_anchors.bottomRight.x()-@_anchors.topLeft.x()
        height: @_anchors.bottomRight.y()-@_anchors.topLeft.y()
    # scaling by bottomRight anchor
    else if @_anchors.bottomRight.isDragging()
      @_rect.size
        width:  @_anchors.bottomRight.x()-@_anchors.topLeft.x()
        height: @_anchors.bottomRight.y()-@_anchors.topLeft.y()
    # scaling by topRight anchor
    else if @_anchors.topRight.isDragging()
      @_rect.y(@_anchors.topRight.y())
      .size
        width:  @_anchors.topRight.x()    - @_anchors.topLeft.x()
        height: @_anchors.bottomRight.y() - @_anchors.topRight.y()
    # scaling by bottomLeft anchor 
    else if @_anchors.bottomLeft.isDragging()
      @_rect.x(@_anchors.bottomLeft.x())
      .size
        width:  @_anchors.bottomRight.x() - @_anchors.bottomLeft.x()
        height: @_anchors.bottomLeft.y()  - @_anchors.topLeft.y()
    # notify listeners about changed attributes
    @setTransformRectAttributes
      size: @_rect.size()
      position: @_rect.position()
    # rotation anchor is beeing dragged
    # else if @_anchors.rotate.isDragging()
    #   # rotation origin point
    #   origin = @_anchors.center.getAbsolutePosition()
    #   # normalize rect local position
    #   @_rect.position
    #     x: 0
    #     y: 0
    #   # move transform group to origin
    #   @setAbsolutePosition(origin)
    #   # # set center point to offset
    #   .offset
    #     x: @_rect.width()/2
    #     y: @_rect.height()/2
    #   # compute angle
    #   deg = @_getAngle
    #     x: @getStage().getPointerPosition().x - origin.x
    #     y: @getStage().getPointerPosition().y - origin.y
    #   # perform rotation
    #   @setRotation(deg)
    # adjust children position an size
    # @_adjustChildren()
    # sync rect position and scale

  ###*
  # Positions anchors to their corresponding positions within rect
  # topLeft-anchor at the top-left corner of the rect
  # bottomRight-anchor at the bottom-right corner of the rect
  # center-anchor at the center point of the rect
  # @private
  # @method _adjustTransformConrols
  ###
  _adjustTransformConrols: ->
    # first scale transform controls
    @_rect.strokeWidth(@_strokeWidth/@getAnchorScale())
    @_rotateAnchorLine.strokeWidth(@_strokeWidth/@getAnchorScale())
    for anchorName, anchor of @_anchors
      anchor.radius(@_anchorRadius/@getAnchorScale()) 
            .strokeWidth(@_strokeWidth/@getAnchorScale()) 
    # adjust center-anchor
    @_anchors.center.position
      x: @_rect.x() + @_rect.width()/2
      y: @_rect.y() + @_rect.height()/2
    # adjust topLeft-anchor
    @_anchors.topLeft.position(@_rect.position())
    # adjust top right anchor
    @_anchors.topRight.position
      x: @_rect.x() + @_rect.width()
      y: @_rect.y()
    # adjust bottomRight-anchor
    @_anchors.bottomRight.position
      x: @_rect.x() + @_rect.width()
      y: @_rect.y() + @_rect.height()
    # adjust bottomLeft-anchor
    @_anchors.bottomLeft.position
      x: @_rect.x()
      y: @_rect.y() + @_rect.height()
    # # rotate anchor
    # @_anchors.rotate.position
    #   x: @_rect.x() + @_rect.width()/2
    #   y: @_rect.y() + @_rect.height() + @_rotateAnchorRectDistance
    # # line between rect and rotate anchor
    # @_rotateAnchorLine.points([
    #   @_anchors.rotate.position().x    # x1
    #   @_rect.y() + @_rect.height()      # y1
    #   @_anchors.rotate.position().x    # x2
    #   @_anchors.rotate.position().y - @_anchors.rotate.radius() # y2
    # ])
    
  # ###*
  # # Gets the counterclockwise angle in degrees between the
  # # positive Y axis and a given point. 
  # # @param {Object} point Point of the form (x, y) 
  # # @param {Number} point.x x-coordinate
  # # @param {Number} point.y y-coordinate
  # # @return {Number} a number between Math.PI and -Math.PI
  # ###
  # _getAngle: (point) ->
  #   (Math.atan2(point.y, point.x) - Math.PI / 2) * (180/Math.PI)

  # ###*
  # # Gets the point of the line that is closest to a given point.
  # # https://github.com/soloproyectos/jquery.transformtool
  # # @param {Object} point Point of the form (x, y)
  # # @param {Line} line  Line
  # # @return {Object} a point of the line of the form (x, y)
  # ###
  # _getNearestPoint: (line, point) ->
  #   a = line.getPoint()
  #   v = line.getVector()
  #   x = ((point.x - a.x) * v.x + (point.y - a.y) * v.y) /
  #       (Math.pow(v.x, 2) + Math.pow(v.y, 2))
  #   r =
  #     x: a.x + v.x * x
  #     y: a.y + v.y * x
  #   r

###*
# Sets scale factor of transform controls (rect stroke and anchor radius)
# @method setAnchorScale
# @param {Number} scale
# @default 1
# @return {MBCTransformControlGroup}
###  
###*
# Returns scale factor of transform controls (rect stroke and anchor radius)
# @method getAnchorScale
# @return {Number} Scale factor of transform controls
### 
Kinetic.Factory.addGetterSetter(Kinetic.MBCTransformControlGroup, 'anchorScale', 1)

###*
# @method setTransformRectAttributes
# @param {Object} attr
# @param {Number} attr.position.x
# @param {Number} attr.position.y
# @param {Number} attr.size.width
# @param {Number} attr.size.height
# @return {MBCTransformControlGroup}
###  
Kinetic.Factory.addSetter(Kinetic.MBCTransformControlGroup, 'transformRectAttributes')

###*
# Sets drag bounds
# @method setDragBounds
# @param {Object} dragBounds
# @param {Number} dragBounds.x
# @param {Number} dragBounds.y
# @param {Number} dragBounds.width
# @param {Number} dragBounds.height
# @return {MBCTransformControlGroup}
###  
###*
# Returns drag bounds
# @method getDragBounds
# @return {Object} Drag bounds (x/y & w/h)
### 
Kinetic.Factory.addGetterSetter(Kinetic.MBCTransformControlGroup, 'dragBounds')

###*
# Sets rect min size
# @method setMinSize
# @param {Object} minSize
# @param {Number} minSize.width
# @param {Number} minSize.height
# @default {width:50, height:50}
# @return {MBCTransformControlGroup}
###  
###*
# Returns mins size of rect
# @method getMinSize
# @return {Object} Min size of rect (w/h)
### 
Kinetic.Factory.addGetterSetter(Kinetic.MBCTransformControlGroup, 'minSize', {width:0, height:0})

# make MBCTransformControls-methods available for Collections (in each() method for example)
Kinetic.Collection.mapMethods(Kinetic.MBCTransformControlGroup)