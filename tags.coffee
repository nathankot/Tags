###
Simple autocomplete plugin
with full keyboard navigation.
works great with the tagbox plugin

@author Bastian Allgeier <bastian@getkirby.com>
@copyright Bastian Allgeier 2012
@license MIT
###
(($) ->
  $.autocomplete = (element, url, options) ->
    defaults =
      url: false
      apply: (string) ->
        $element.val string

    plugin = this
    plugin.settings = {}
    $element = $(element)
    element = element
    plugin.init = ->
      plugin.settings = $.extend({}, defaults, options)
      plugin.input = $element
      plugin.ignore = []
      plugin.data = {}
      plugin.open = false
      plugin.load()
      plugin.blocker = $("<div class=\"autocomplete-blocker\"></div>").css(
        position: "fixed"
        top: 0
        left: 0
        right: 0
        bottom: 0
        "z-index": 1999
      ).hide()
      plugin.box = $("<div class=\"autocomplete\"></div>").css("z-index", 2000)
      plugin.ul = $("<ul></ul>")
      plugin.blocker.click (e) ->
        plugin.kill()
        plugin.input.focus()
        e.stopPropagation()

      $element.keyup (e) ->
        plugin.pos = plugin.selection()
        switch e.keyCode
          when 13 # enter
            plugin.apply()
          when 27 # esc
            plugin.kill()
          # up
          when 38, 40 # down
            false
          when 39 # right
            value = plugin.value()
            plugin.apply()  if value.length > 0 and plugin.pos is plugin.input.val().length
          when 188 # ,
            plugin.apply()
          else
            plugin.complete $(this).val()

      $element.keydown (e) ->
        plugin.pos = plugin.selection()
        switch e.keyCode
          when 9 # tab
            if plugin.value().length > 0
              plugin.apply()
              return false
            else
              return true
          when 38 # up
            plugin.prev()
            false
          when 40 # down
            plugin.next()
            false

      plugin.box.click (e) ->
        e.stopPropagation()

      $("body").append plugin.box
      $("body").append plugin.blocker
      $(window).resize plugin.position
      plugin.position()

    plugin.load = ->
      if typeof url is "object"
        plugin.data = url
      else
        $.getJSON url, (result) ->
          plugin.data = result


    plugin.complete = (search) ->
      plugin.kill()
      plugin.position()
      counter = 0
      search = $.trim(search)
      return false  if search.length is 0
      reg = new RegExp("^" + search, "i")
      result = plugin.data.filter((str) ->
        str  if plugin.ignore.indexOf(str) is -1 and str.match(reg)
      )
      result = result.slice(0, 5)
      $.each result, (i, string) ->
        li = $("<li>" + string + "</li>")
        li.click ->
          plugin.apply string

        li.mouseover ->
          plugin.ul.find(".selected").removeClass "selected"
          li.addClass "over"

        li.mouseout ->
          li.removeClass "over"

        plugin.ul.append li
        li.addClass "first selected"  if counter is 0
        counter++

      if counter > 0
        plugin.box.append plugin.ul.show()
        plugin.blocker.show()
        plugin.open = true

    plugin.kill = ->
      plugin.blocker.hide()
      plugin.ul.empty().hide()
      plugin.open = false

    plugin.apply = (string) ->
      string = plugin.value()  unless string
      plugin.settings.apply.call plugin, string

    plugin.value = ->
      plugin.selected().text()

    plugin.selected = ->
      plugin.ul.find ".selected"

    plugin.select = (element) ->
      plugin.deselect()
      element.addClass "selected"

    plugin.deselect = ->
      plugin.selected().removeClass "selected"

    plugin.prev = ->
      sel = plugin.selected()
      prev = sel.prev()
      plugin.select prev  if prev.length > 0

    plugin.next = ->
      sel = plugin.selected()
      next = (if (sel.length > 0) then sel.next() else plugin.ul.find("li:first-child"))
      plugin.select next  if next.length > 0

    plugin.selection = ->
      i = plugin.input[0]
      v = plugin.val
      return i.selectionStart  unless i.createTextRange
      r = document.selection.createRange().duplicate()
      r.moveEnd "character", v.length
      return v.length  if r.text is ""
      v.lastIndexOf r.text

    plugin.position = ->
      pos = $element.offset()
      height = $element.innerHeight()
      pos.top = pos.top + height + 10
      plugin.box.css pos

    plugin.init()

  $.fn.autocomplete = (url, options) ->
    @each ->
      if `undefined` is $(this).data("autocomplete")
        plugin = new $.autocomplete(this, url, options)
        $(this).data "autocomplete", plugin

) jQuery

###
Tag input plugin
works great with the autocomplete plugin

@author Bastian Allgeier <bastian@getkirby.com>
@copyright Bastian Allgeier 2012
@license MIT
###
(($) ->
  $.tagbox = (element, options) ->
    defaults =
      url: false
      autocomplete: {}
      lowercase: true
      classname: "tagbox"
      separator: ", "
      duplicates: false
      minLength: 1
      maxLength: 140
      keydown: ->

      onAdd: ->

      onRemove: ->

      onDuplicate: ->
        plugin.input.focus()

      onInvalid: ->
        plugin.input.focus()

      onReady: ->

    plugin = this
    autocomplete = null
    plugin.settings = {}
    $element = $(element)
    element = element
    plugin.init = ->
      plugin.settings = $.extend({}, defaults, options)
      $name = $element.attr("name")
      $id = $element.attr("id")
      $val = $element.val()
      plugin.index = []
      plugin.val = ""
      plugin.focused = false
      plugin.origin = $element.addClass("tagboxified").hide()
      plugin.box = $("<div class=\"" + plugin.settings.classname + "\"><ul><li class=\"new\"><input autocomplete=\"off\" tabindex=\"0\" type=\"text\" /></li></ul></div>")
      plugin.input = plugin.box.find("input").css("width", 20)
      plugin.bhits = 0
      plugin.lhits = 0
      if plugin.settings.url
        autocompleteDefaults = apply: (string) ->
          plugin.add string
          @kill()
          plugin.input.focus()


        # initialize the autocomplete plugins with a default event
        plugin.input.autocomplete plugin.settings.url, $.extend({}, autocompleteDefaults, plugin.settings.autocomplete)

        # store the autocomplete plugin object
        plugin.autocomplete = plugin.input.data("autocomplete")

        # add autocomplete custom events to the tagbox plugin
        plugin.settings.onAdd = (tag) ->
          plugin.autocomplete.ignore = plugin.serialize()

        plugin.settings.onRemove = (tag) ->
          plugin.autocomplete.ignore = plugin.serialize()
      plugin.origin.before plugin.box
      plugin.measure = $("<div style=\"display: inline\" />").css(
        "font-size": plugin.input.css("font-size")
        "font-family": plugin.input.css("font-family")
        visibility: "hidden"
        position: "absolute"
        top: -10000
        left: -10000
      )
      $("body").append plugin.measure
      plugin.box.click (e) ->
        plugin.focus()
        plugin.input.focus()
        e.stopPropagation()

      plugin.input.keydown (e) ->
        plugin.val = plugin.input.val()
        plugin.position = plugin.selection()
        plugin.settings.keydown.call plugin, e, plugin.val

      plugin.input.keyup (e) ->
        plugin.val = plugin.input.val()
        plugin.position = plugin.selection()
        plugin.resize plugin.val
        plugin.add plugin.val  if plugin.val.match(new RegExp(plugin.settings.separator))

      plugin.input.focus (e) ->
        plugin.input.focused = true
        plugin.deselect()
        plugin.bhits = 0
        plugin.focus()

      plugin.input.blur (e) ->
        plugin.input.focused = false
        plugin.bhits = 0
        plugin.blur()  if plugin.val.length is 0

      plugin.settings.onReady.call this
      #backspace
      # left
      # right
      # tab
      # enter
      # ,
      $(document).keydown((e) ->
        return true  unless plugin.focused
        switch e.keyCode
          when 8
            unless plugin.input.focused
              plugin.remove()
              return false
            if plugin.val.length is 0
              plugin.next()
              return false
            else if plugin.position is 0
              if plugin.bhits > 0
                plugin.bhits = 0
                plugin.next()
                return false
              plugin.bhits++
          when 37
            return plugin.previous()  unless plugin.input.focused
            if plugin.val.length is 0
              plugin.next()
              return false
            else if plugin.position is 0
              if plugin.lhits > 0
                plugin.lhits = 0
                plugin.next()
                return false
              plugin.lhits++
          when 39
            unless plugin.input.focused
              plugin.next()
              return false
          when 9
            if plugin.input.focused and plugin.val.length > plugin.settings.minLength
              plugin.add plugin.val
              return false
            else if plugin.selected().length > 0
              plugin.deselect()
              plugin.input.focus()
              return false
          when 13, 188
            if plugin.input.focused
              plugin.add plugin.val  unless plugin.settings.autocomplete
              return false
      ).click (e) ->
        plugin.add plugin.val  if plugin.val.length > 0

      plugin.add $val  if $val.length > 0

    plugin.resize = (value) ->
      plugin.measure.text value
      plugin.input.css "width", plugin.measure.width() + 20

    plugin.focus = (input) ->
      return true  if plugin.focused
      $(".tagboxified").not(plugin.origin).each ->
        $(this).data("tagbox").blur()  if $(this).data("tagbox")

      plugin.box.addClass "focus"
      plugin.focused = true
      input = true  if input is `undefined`
      plugin.input.focus()  if input isnt false


    plugin.blur = ->
      return true  unless plugin.focused
      plugin.box.removeClass "focus"
      plugin.focused = false
      plugin.input.blur()
      plugin.deselect()

    plugin.tag = (tag) ->
      tag = tag.replace(/,/g, "").replace(/;/g, "")
      tag = tag.toLowerCase()  if plugin.settings.lowercase
      $.trim tag

    plugin.serialize = ->
      plugin.index

    plugin.string = ->
      plugin.serialize().toString()

    plugin.add = (tag) ->
      plugin.input.val ""
      if not tag and plugin.val.length > 0
        return plugin.add(plugin.val)
      else return true  unless tag
      if $.isArray(tag) or tag.match(new RegExp(plugin.settings.separator))
        tags = (if ($.isArray(tag)) then tag else tag.split(plugin.settings.separator))
        $.each tags, (i, t) ->
          plugin.add t

        return true
      tag = plugin.tag(tag)
      return plugin.settings.onInvalid.call(plugin, tag, length)  if tag.length < plugin.settings.minLength or tag.length > plugin.settings.maxLength
      return plugin.settings.onDuplicate.call(plugin, tag)  if $.inArray(tag, plugin.index) > -1  if plugin.settings.duplicates is false
      plugin.index.push tag
      li = $("<li><span class=\"tag\"></span><span class=\"delete\">&#215;</span></li>").data("tag", tag)
      li.find(".tag").text tag
      li.find(".delete").click ->
        plugin.remove li

      li.click (e) ->
        plugin.blur()
        e.stopPropagation()
        plugin.select li

      li.focus (e) ->
        plugin.select li

      plugin.input.parent().before li
      plugin.input.val ""
      plugin.input.css "width", 20
      serialized = plugin.serialize()
      plugin.origin.val serialized.join(plugin.settings.separator)
      plugin.settings.onAdd.call plugin, tag, serialized, li

    plugin.select = (element) ->
      if typeof element is "string"
        element = plugin.find(element)
        return false  unless element
      return false  if element.length is 0
      plugin.input.blur()
      @deselect()
      element.addClass "selected"
      plugin.focus false

    plugin.selected = ->
      plugin.box.find ".selected"

    plugin.deselect = ->
      selected = plugin.selected()
      selected.removeClass "selected"

    plugin.find = (tag) ->
      element = false
      plugin.box.find("li").not(".new").each ->
        element = $(this)  if $(this).data("tag") is tag

      element

    plugin.remove = (element) ->
      plugin.input.val ""
      if typeof element is "string"
        element = plugin.find(element)
        return false  unless element
      selected = plugin.selected()
      element = selected.first()  if not element and selected.length > 0
      previous = plugin.previous(true)
      (if (previous.length is 0) then plugin.next() else plugin.select(previous))
      tag = element.find(".tag").text()
      plugin.removeFromIndex tag
      element.remove()
      serialized = plugin.serialize()
      plugin.origin.val serialized
      plugin.settings.onRemove.call plugin, tag, serialized, element

    plugin.removeFromIndex = (tag) ->
      i = plugin.index.indexOf(tag)
      plugin.index.splice i, 1

    plugin.selection = ->
      i = plugin.input[0]
      v = plugin.val
      return i.selectionStart  unless i.createTextRange
      r = document.selection.createRange().duplicate()
      r.moveEnd "character", v.length
      return v.length  if r.text is ""
      v.lastIndexOf r.text

    plugin.previous = (ret) ->
      sel = plugin.selected()
      prev = (if (sel.length is 0) then plugin.box.find("li").not(".new").first() else sel.prev().not(".new"))
      (if (ret) then prev else plugin.select(prev))

    plugin.next = (ret) ->
      sel = plugin.selected()
      next = (if (sel.length is 0) then plugin.box.find("li").not(".new").last() else sel.next())
      (if (ret) then next else (if (next.hasClass("new")) then plugin.input.focus() else plugin.select(next)))

    plugin.init()

  $.fn.tagbox = (options) ->
    @each ->
      if `undefined` is $(this).data("tagbox")
        plugin = new $.tagbox(this, options)
        $(this).data "tagbox", plugin

) jQuery
