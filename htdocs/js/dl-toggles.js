// toggling event visibility
// v5 Kent Brewster, 7/11/2006
// questions? comments? dirty jokes?
// please leave 'em here:
// http://kentbrewster.com/toggle
// feel free to use or abuse this code
// but please leave this notice intact

// namespace protection: one global variable to rule them all

var KENTBREW = window.KENTBREW || {};

KENTBREW.toggle = function() {

   // private bucket for scope-sensitive variables -- thanks, Dustin
   var $ = {};
   
   return {   
      init : function(selfObj, toggleClass, toggleClosed, toggleHidden) {
         // first, a brute-force hack to decode the calling function's 
         // name and store it upstairs, safe from scope creep
         $.selfName = this.getSelfName(selfObj);
         
         // we're going to hang all variables that might be confused 
         // by scope changes later onto KENTBREW.variables, which is aliased to $.  
         // In this case it's three class names, fed in from the init call:

         $.toggleClass = toggleClass;
         $.toggleClosed = toggleClosed;
         $.toggleHidden = toggleHidden;
         
         // crawl through the document, look for toggled elements
         this.crawl(document.body);
      },
      crawl : function(el) {
         // get this element's next sibling
         var nextSib = this.getNextSibling(el);

         // if it has a class name, the class name matches our toggle class, and there's something there to toggle:
         if (el.className && el.className.match($.toggleClass) && nextSib)
         {
            // to avoid scope loss, attach onmouseup to the toggle function with eval and $.selfName
            el.onmouseup = function () { 
               eval($.selfName + '.toggleState(this)'); 
            };
            
            // if the next sib ought to be hidden and it isn't already, hide it
            if (el.className.match($.toggleClosed) && nextSib && !nextSib.className.match($.toggleHidden)) {
               nextSib.className += ' ' + $.toggleHidden;
            }
         }

         // is there more to do? Do it, if so:
         if (el.firstChild) {
            this.crawl(el.firstChild);
         }
         
         if (nextSib) {
            this.crawl(nextSib);
         }
      },
      toggleState : function(el) {
         // change the style of the triggering element
         if(el.className.match($.toggleClosed)) {
            el.className = el.className.replace($.toggleClosed, '');
         }
         else {
            el.className = el.className + ' ' + $.toggleClosed;
         }

         // the norgie we clicked has changed.  Now we need to
         // change the style of its parent node's next sibling
         var nextSib = this.getNextSibling(el);

         // check if it's really there; other scripts could have removed it
         if(nextSib && nextSib.className.match($.toggleHidden)) {
            nextSib.className = nextSib.className.replace($.toggleHidden, '');
         }
         else {
            nextSib.className += ' ' + $.toggleHidden;
         }
      },
      getNextSibling : function(el) {
         var nextSib = el.nextSibling;
         // hack for Gecko browsers
         if (nextSib && nextSib.nodeType != 1) {
            nextSib = nextSib.nextSibling;
         }
         return nextSib;
      },
      getSelfName : function(selfObj) {
         // icky hack to get contents of selfObj into a string
         // suggestions will be gratefully appreciated
         var s = document.createElement('SPAN');
         s.innerHTML = selfObj;
         // cut the fat, split the meat to namespace array
         var nameSpace = s.innerHTML.split('{')[1].split('(')[0].replace(/^\s+/, '').split('.');
         var selfName = '';
         // here we assume that the main function is up one level from the init function
         for (var i = 0; i < nameSpace.length - 1; i++) {
            if (selfName) {
               selfName += '.';
            }
            selfName += nameSpace[i];
         }
         return selfName;
      }
   };
}();

// feed it the CSS class names of your choice
window.onload = function() { 
   
   KENTBREW.toggle.init(arguments.callee, 'toggle', 'closed', 'hidden');
}();
