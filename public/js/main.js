
/* Precompile templates */
var card_frame_template   = Handlebars.compile( $("#cardFrameTemplate").html() );
var card_view_template    = Handlebars.compile( $("#cardViewTemplate").html() );
var card_edit_template    = Handlebars.compile( $("#cardEditTemplate").html() );
var field_template        = Handlebars.compile( $( "#editFieldTemplate" ).html() );

$(document).ready(function(){

  /* Hide working div */
  $( '#working' ).hide();
  $( "#working" ).click(function(){ 
    $(this).hide();
  });
  $( '#message' ).hide();
  $( "#message" ).click(function(){ 
    $(this).hide();
  });

  /* $( "#search" ).focus(function(){
    $(this).val('');
  }); */

  /* Handle drop-down search box. */
  $(function() {
    $( "#search" ).autocomplete({
      autoFocus: true,
      minLength: 1,
      source: function( request, response ) {
          var term = request.term;

          $.getJSON( "/search", request, function( data, status, xhr ) {
            if (check_json_response(data))
              response( data['value'] );
          }).fail(function(){
            display_error("Server communication error");
          });
        },
      select: function( event, ui ) {
          console.log(event);
          var id = $( "#search" ).val();
          fetch_card(id);
        }
      });
  });

});


// Read from the search box and retrieve
function go(){
  var id = $( "#search" ).val();
  fetch_card(id);
}

// Make a get request, handling the UI and server API
function get(endpoint, callback){

  // show activity icon
  $("#working").show();

  $.get( endpoint, function( data ) {

    data = JSON.parse(data);
  
    if(check_json_response(data))
      callback(data['value']);

    $( '#working' ).hide();
  }).fail(function(){
    display_error("Server communication error");
  });

}

// Make a POST request, handling the UI and server API 
// (success/failure)
//
// Varargs: endpoint and function or endpoint payload and function
function post(endpoint, payload, callback){
 
  // Varargs
  if (typeof callback == 'undefined'){
    callback = payload;
    payload = {};
  }

  // show activity icon
  $("#working").show();

  // POST and then un-edit
  $.post( endpoint, payload, function( data ) {
   
    data = JSON.parse(data);

    if(check_json_response(data))
      callback(data["value"]);

    $( '#working' ).hide();
  }).fail(function(){
    display_error("Server communication error");
  });

}


/* Check a response succeeded.  Returns true or false. */
function check_json_response(response) {
  if (response['success'] != true) {
    display_error(response['value']);
    return false;
  }
  return true;
}

/* Display an error to the user */
function display_error(msg) {
  $("#message").removeClass('message');
  $("#message").addClass('warning');
  $("#message").html(msg);
  $("#message").show();
}

/* Display a message to the user */
function display_message(msg, timeout) {

  $("#message").removeClass('warning');
  $("#message").addClass('message');
  $("#message").html(msg);
  $("#message").show();

  if(typeof timeout != "undefined"){
    setTimeout(function(){
      $("#message").hide();
    }, timeout);
  }
}



/* Rebuild the internal index */
function rebuild_index(){
  post('/rebuild-index', function(msg){
    display_message(msg, 1000);
  });
}



/* Manage search query to fetch a card */
function fetch_card(id) {

  get('/get/' + id, function(response){
    
    // Compute JS ID
    response['js_id']         = to_js_id(response['id']);

    // Load viewable content
    hide_card(id);  // TODO: check if card already exists in DOM?
    partial_card_frame(response);

    // If the card is null, render edit
    if (JSON.stringify(response['card']) == '{}'){    // FIXME: must be a better test for emptiness
      partial_edit_card(response);
      add_field(response['id']);
    }else{
      partial_view_card(response);
    }

  });
}




/* Load the edit partial for a card */
function edit_card(id) {
  
  // Re-read card in case it's changed since it
  // was displayed
  get('/get/' + id, function(response){
    
    // Compute JS ID
    var js_id = to_js_id(response['id']);
    response['js_id']         = js_id

    partial_edit_card(response);

  });
}

/* Render the card frame only 
 * Requires that response has js_id in it.
 * */
function partial_card_frame(response){
      

    // Load the card frame
    response['type_icon']     = response['is_template'] ? 'code' : 'credit-card';
    $( "#content" ).prepend( card_frame_template(response) );

}

/* Populate a card container with the view partial */
function partial_view_card(response){
    
    // Add the icon type depending on the template state
    response['fields']        = keys(response['card']);

    // Autolink fields
    $.each(response['card'], function(index, value){
      if (typeof value == "string") {
        // console.log(index + ":" + value);
        response['card'][index] = value.autoLink( {target: '_blank'} );
      }
    });

    // Render the card frame
    // And the card content
    $( "#card-" + response['js_id'] + " .card-content" ).html( card_view_template(response) );

    // Onclick of any key, copy the value to the clipboard
    $( ".key" ).click( function(){
      var value = $(this).siblings(".value")[0];
      select_text(value);
    });
}



/* Populate a card container with the edit partial */
function partial_edit_card(response){
   
    // Compile edit template
    // Display edit template
    $( "#card-" + response['js_id']+ " .card-content" ).html( card_edit_template(response) );

    // Add each field
    $.each( response['card'], function(index, value){
      add_field(response['id'], index, value);
    });

}



/* Add a field to a card's editable thing 
 * key and value are optional!
 * */
function add_field(id, key, value) {
  
  var uuid = ('' + Math.random()).replace(/\./g, '');

  $( "#card-fields-" + to_js_id(id) ).append( field_template( {js_id: to_js_id(id), rand: uuid, key: key, value: value} ) );

  // TODO: Enable CodeMirror on the textarea
  // CodeMirror.fromTextArea( $("#card-field-id-" + uuid + " .field-value").get(0), 
  //     {
  //         mode: 'markdown',
  //         lineNumbers: true,
  //         viewportMargin: Infinity,
  //     }
  // );
  //
  $("#card-field-id-" + uuid + " .field-value").autogrow();

  // Focus the new key
  $( "#card-field-id-" + uuid + " .field-key" ).focus();
}

/* Remove a field from the edit pane */
function remove_field(elid) {
  $( "#" + elid ).detach();
}



/* Discard edits. */
function discard_edits(id) {

  var edit_data = load_edit_data(id);
  
  if (confirm("Discard edits?")){
    hide_card(id);

    // TODO: if card is empty, do not reload it.
    if(JSON.stringify(edit_data) != '{}')   // FIXME: must be a better test for emptiness
      fetch_card(id);
  }
}





/* Save Edits */
function save_edits(id) {
  var fields = load_edit_data(id);

  // POST and then un-edit
  post( "/edit/" + id, { fields: fields }, function( id_edited ) {
  
    if(id_edited == id){
      hide_card(id);
      fetch_card(id);
    }else{
      // TODO: error msg.
    }
  });
}



/* Parse edit data from the DOM into an object. */
function load_edit_data(id) {
    // Collect together data from the edit container
  var el_fields = $( "#card-fields-" + to_js_id(id) ).children( ".card-field" );
  var fields    = {};

  el_fields.each( function( i, field ){

    var key   = $(field).children( ".field-key" )[0];
    var value = $(field).children( ".field-value")[0];

    // Load value from elements if they are found
    if (typeof key != "undefined" )
      key = $(key).val();
    if (typeof value != "undefined" )
      value = $(value).val();

    // If the key exists, pop it in the data hash
    if (typeof key != "undefined" && key != "")
      fields[key] = value;
  });

  return fields;
}




/* Deletes a card from the server */
function delete_card(id) {
    
  if (confirm("Delete card " + id + "?")){
    post( "/delete/" + id, function( id_deleted ) {

      // The service echoes the ID it has bookmarked,
      // so check this.
      if (id_deleted == id){
        hide_card(id);
      }else{
        // TODO: warn!
      }
    });
  }
}











/* Clears the whole content area */
// FIXME: should warn about edits!
function clear_all() {
  if (confirm("Clear all cards?")) {
    $( "#content" ).html('');
  }
}







/* Load the bookmark partial down the LHS */
function populate_bookmark_list() {
  get( '/bookmarks', function(list){
    var bookmarks_template = Handlebars.compile( $("#bookmarksTemplate").html() );

    // Make sure we know the JS ID and ID of each
    var bookmarks_list = [];
    $.each(list, function(index, value){
      bookmarks_list.push( {id: value, js_id: to_js_id(value)} );
    });

    $("#bookmarks").html( bookmarks_template({bookmarks: bookmarks_list}) );
  });
}


/* Toggle the bookmarked status of the card ID */
function toggle_bookmark(id){

  post( "/toggle-bookmark/" + id, function( id_toggled ) {

    // The service echoes the ID it has bookmarked,
    // so check this.
    if (id_toggled == id){

      var marker = $( ".bookmark-marker-" + to_js_id(id) );

      if (marker) {
        if (marker.hasClass( 'fa-bookmark')){
          marker.removeClass( 'fa-bookmark' );
          marker.addClass( 'fa-bookmark-o' );
        }else{
          marker.removeClass( 'fa-bookmark-o' );
          marker.addClass( 'fa-bookmark' );
        }
      }
    }
 
    // Reload bookmark list
    populate_bookmark_list();
  });
}








/* Hide a card from the display */
function hide_card(id) {
  $( "#card-" + to_js_id( id ) ).detach();
}

/* Sanitise an ID to avoid having dots in. */
function to_js_id(id) {
  return ('' + id).replace(/\./g, '_');
}

/* Return an array of keys from an object */
function keys(obj) {
  var keys = [];

  $.each(obj, function(index, value){
    keys.push(value);
  });

  return keys;
}


// Many thanks to Jason,
// http://stackoverflow.com/questions/985272/selecting-text-in-an-element-akin-to-highlighting-with-your-mouse
function select_text(element) {
    var doc = document
        , range, selection
    ;    
    if (doc.body.createTextRange) {
        range = document.body.createTextRange();
        range.moveToElementText(element);
        range.select();
    } else if (window.getSelection) {
        selection = window.getSelection();        
        range = document.createRange();
        range.selectNodeContents(element);
        selection.removeAllRanges();
        selection.addRange(range);
    }
}



