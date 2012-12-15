// -*-mode: C++; style: K&R; c-basic-offset: 4 ; -*- */
//
//  Some simple JavaScript functions for form persistance / autosave.
//
// Sub-optimal.
//
//
// Steve
// --
// $Id: form_autosave.js,v 1.3 2006-12-24 14:50:01 steve Exp $



var t;
var f;
var i;
var j;
var e = new Array();
var eo;
var saving;


//
//  Add listeners
//
function start() 
{
    //
    // Get all the form elements we care about.
    //
    t = document.getElementsByTagName('textarea'); // textareas
    f = document.getElementsByTagName('form');     // forms
    i = document.getElementsByTagName('input');    // inputs

    // Strip i down to just text inputs
    var newi = new Array();
    for (j=0;j<i.length;j++) {
        if (i[j].type == 'text') {
            newi.push(i[j]);
        }
    }
    i = newi;

    //
    //  Add the listeners.
    //
    for (j = 0; j < f.length; j++) 
    {
        f[j].addEventListener("submit", clear, false);
    }
    for (j = 0; j < i.length; j++) 
    {
        i[j].addEventListener("keyup", prepsave, false);
    }
    for (j = 0; j < t.length; j++) 
    {
        t[j].addEventListener("keyup", prepsave, false);
    }
    offer_repopulate();
}


//
//  Clear saved data.
//
function clear() 
{
    var today = new Date();
    var expiry = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000); // In the past to expire cookie
    document.cookie = "FormsSavedData=; expires=" + expiry.toGMTString() + "; path=/";
}


//
// Get the value of a cookie
//
function getCookie(name) 
{
    var re = new RegExp(name + "=([^;]+)");
    var value = re.exec(document.cookie);
    return (value != null) ? unescape(value[1]) : false;
}


//
// Set the value of a cookie.
//
function setCookie(name, value) 
{
    var today = new Date();
    var expiry = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000); // Expires after a month
    
    document.cookie = name + "=" + escape(value) + "; expires=" + expiry.toGMTString() + "; path=/";
}

//
//
//
function prepsave() 
{
    clearInterval(saving);
    saving = setInterval(savedata, 500);
}

//
//  Save the data.
//
function savedata() 
{
    e = new Array();
    for (j=0;j<i.length;j++) 
    {
        e.push(i[j].value.toString());
    }
    for (j=0;j<t.length;j++) 
    {
        e.push(t[j].value.toString());
    }
    setCookie('FormsSavedData', e.join("|"));
    clearInterval(saving);
}

//
//  Repopulate our saved data.
//
function repopulate() 
{
    eo = getCookie('FormsSavedData').split("|");
    for (j=0;j<i.length;j++) 
    {
        var v = eo.shift();
        if ( v != null ) {  i[j].value = v; }
    }
    for (j = 0; j < t.length; j++) 
    {
        var v = eo.shift();
        if ( v != null ) { t[j].value = v; }
    }

    // clear the saved cookie.
    clear();
}


//
//  Offer to repopulate our saved data.
//
function offer_repopulate() 
{
    if (getCookie('FormsSavedData')) 
    {
        if ( confirm('Restore saved contents of this form?') ) 
        {
            repopulate();
        }
    }
}


//
//  Start us up.
//	
window.addEventListener("load", start, false);
