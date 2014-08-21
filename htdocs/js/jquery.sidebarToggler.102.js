(function($) {$.fn.toggleSidebar=function(options,arg) {var opts = $.extend({}, $.fn.toggleSidebar.defaults, options);return this.each(function(){$$ = $(this);var o = $.meta ? $.extend({}, opts, $$.data()) : opts;var trigger1, triger2;(o.initState=='shown') ? (trigger1=o.triggerShow, trigger2=o.triggerHide) : (trigger1=o.triggerHide, trigger2=o.triggerShow);$('<a class="trigger" href="#" />').text(trigger2).insertBefore('#' + $$.attr("id") + ' ' + o.sidebar);var $trigger = $$.find('a.trigger'),
$thisPanel = $$.find(o.sidebar),
$main = $$.closest(o.wrapper).find(o.mainContent),
pw = $thisPanel.width(),
tw = $trigger.outerWidth(true),
hTimeout=null;init = $.fn.toggleSidebar.init[o.init];init($$, $trigger, $thisPanel, $main, pw, tw, o);if(o.event=='click'){var ev = 'click';}else{if(o.focus){var addev = ' focus';}else{var addev = '';}if(o.addEvents){var addev = ' ' + o.addEvents;}else{var addev = '';}
var ev = 'mouseenter' + addev;}
$$.delegate('a.trigger', ev, function(ev) {ev.preventDefault();var $trigger = $(this),
setanim = (o.attr && $.isFunction($.fn.toggleSidebar.animations[$trigger.attr(o.attr)])) ? $trigger.attr(o.attr) : null, 
animation=setanim || o.animation,
anim = $.fn.toggleSidebar.animations[animation];if($.isFunction(anim)){if(o.event=='click') {anim($$, $trigger, $thisPanel, $main, pw, tw, o);}else{hTimeout=window.setTimeout(function(){anim($$, $trigger, $thisPanel, $main, pw, tw, o);}, o.interval);}}else{}});if(o.event!='click'){$$.delegate('a.trigger', 'mouseleave', function(){window.clearTimeout(hTimeout);});}});};
$.fn.toggleSidebar.defaults = {initState : 'shown',
animation : 'queuedEffects',
init : 'initPositions',
full : false,
position : 'right',
triggerShow : 'Show',
triggerHide : 'Hide',
sidebar : 'div.slide',
mainContent : '#main',
wrapper : '#content',
p : 5,
attr : 'id',
speed : 400,
event : 'click',
addEvents : 'click',
interval : 300};$.fn.toggleSidebar.init = {initPositions : function($$, $trigger, $thisPanel, $main, pw, tw, o) {if(o.initState=='hidden'){var mrg = (o.full==true) ? 0 : tw+o.p;switch (o.position) {case 'right': var pos='right';var margin='margin-right';break;
case 'left': var pos='left';var margin='margin-left';break;
default: var pos='right';var margin='margin-right';}
$(o.sidebar, $$).css(pos, -(pw+1));$main.css(margin,(mrg));$trigger.addClass('collapsed');}}};$.fn.toggleSidebar.animations = {queuedEffects : function($$, $trigger, $thisPanel, $main, pw, tw, o) {if(o.full==true){var mrg=0}else{var mrg=tw+o.p}
$trigger.animate({opacity: 0}, o.speed);if($trigger.text()==o.triggerShow){$main.animate({marginRight: (pw+o.p)}, o.speed, function(){$thisPanel.animate({opacity: 1}, 'fast').animate({right: 0}, o.speed, function(){$trigger.removeClass('collapsed').text(o.triggerHide).animate({opacity: 1}, o.speed);});});}else{$thisPanel.animate({opacity: 0, right: -(pw+1)}, o.speed, function(){$main.animate({marginRight:  (mrg)}, o.speed, function(){$trigger.addClass('collapsed').text(o.triggerShow).animate({opacity: 1}, o.speed);});});};},
concurrentEffects : function($$, $trigger, $thisPanel, $main, pw, tw, o) {if(o.full==true){var mrg=0}else{var mrg=tw+o.p}
$trigger.animate({opacity: 0}, 'fast');if($trigger.text()==o.triggerShow){$main.animate({marginRight: (pw+o.p)}, o.speed, 'linear');$thisPanel.animate({right: 0, opacity: 1}, o.speed, function(){$trigger.removeClass('collapsed').text(o.triggerHide).animate({opacity: 1}, o.speed);});}else{$thisPanel.animate({opacity: 0, right: -(pw+1)}, o.speed, 'linear');$main.animate({marginRight:  (mrg)},  o.speed, function(){$trigger.addClass('collapsed').text(o.triggerShow).animate({opacity: 1}, o.speed);});};},
simpleToggle : function($$, $trigger, $thisPanel, $main, pw, tw, o) {if(o.full==true){var mrg=0}else{var mrg=tw+o.p}if($trigger.text()==o.triggerShow){$trigger.removeClass('collapsed').text(o.triggerHide);$thisPanel.css({right: 0, opacity: 1});$main.css({marginRight: (pw+o.p)});}else{$trigger.addClass('collapsed').text(o.triggerShow);$thisPanel.css({right: -(pw+1), opacity: 0});$main.css({marginRight: (mrg)});};}};})(jQuery);