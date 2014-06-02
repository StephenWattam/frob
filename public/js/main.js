
/* Handle drop-down search box. */
$(function() {
  $( "#search" ).autocomplete({
    minLength: 1,
    source: function( request, response ) {
        var term = request.term;

        $.getJSON( "/search", request, function( data, status, xhr ) {
          // TODO: test data['success'] == true
          response( data['value'] );
        });
      },
    select: function( event, ui ) {
        var id = $( "#search" ).val();
        fetch_card(id);
        $( "#search" ).val("");
      }
    });
});


// Make a get request, handling the UI and server API
function get(endpoint, callback){

  // TODO: show activity icon

  $.get( endpoint, function( data ) {

    // TODO: hide activity icon
    data = JSON.parse(data);
    // TODO: test data['success'] == true and error if not
  
    callback(data['value']);
  });

  // TODO: add failure handler that displays an error message
}

// Make a POST request, handling the UI and server API 
// (success/failure)
function post(endpoint, callback, payload){
  
  if (typeof payload == 'undefined')
    payload = {};

  // TODO: show activity icon

  // POST and then un-edit
  $.post( endpoint, payload, function( data ) {
    
    // TODO: hide activity icon
    data = JSON.parse(data);
    // TODO: test data['success'] == true, error if not

    callback(data["value"]);
  });

  // TODO: add failure handler that displays an error message
}


/* Rebuild the internal index */
function rebuild_index(){
  post('/rebuild-index', function(msg){
    alert('' + msg);
  });
}



/* Manage search query to fetch a card */
function fetch_card(id) {

  get('/get/' + id, function(response){

    // Compute JS ID
    var js_id = to_js_id(response['id']);

    // Add the JS id field
    response['js_id'] = js_id
    // Add the icon type depending on the template state
    response['type_icon'] = response['is_template'] ? 'code' : 'credit-card';
    response['bookmark_icon'] = response['bookmarked'] ? 'fa-bookmark': 'fa-bookmark-o';

    // Render the card frame
    var card_frame = nano($( "#cardFrameTemplate" ).html(), response )
    $( "#content" ).prepend( card_frame );

    // And the card content
    var card_content = nano($( "#cardViewTemplate" ).html(), response )
    $( "#card-" + js_id + " .card-content" ).html( card_content );

    // TODO: render fields
  });
  $.get( "/get/" + id, function( data ) {
    hide_card(id);
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

// -------------------------------




/* Load the edit partial for a card */
function edit_card(id) {
  $.get( "/edit/" + id, function( data ) {
    hide_card(id);
    $( "#content" ).prepend( data );
  });
}

/* Deletes a card from the server */
function delete_card(id) {
    
  if (confirm("Delete card " + id + "?")){
    $.get( "/delete/" + id, function( data ) {

      // The service echoes the ID it has bookmarked,
      // so check this.
      if (data == id){
        hide_card(id);
      }
    });
  }
}

/* Discard edits. */
function discard_edits(id) {

  if (confirm("Discard edits?")){
    hide_card(id);
    fetch_card(id);
  }
}

/* Save Edits */
function save_edits(id) {
  // Collect together data from the edit container
  var el_fields = $( "#card-fields-" + js_id(id) ).children( ".card-field" );
  var fields    = {};

  el_fields.each( function( i, field ){

    var key = $(field).children( ".field-key" )[0];
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


  // POST and then un-edit
  $.post( "/edit/" + id, { fields: fields }, function( data ) {
    if(data == id){
      hide_card(id);
      fetch_card(id);
    }
  })
}



/* Add a field to a card's editable thing 
 * key and value are optional!
 * */
function add_field(id, key, value) {
  
  var uuid = ('' + Math.random()).replace(/\./g, '');

  $( "#card-fields-" + js_id(id) ).append(
    nano( $( "#editFieldTemplate" ).html(), {js_id: js_id(id), rand: uuid, key: key, value: value} )
  );

  // Focus the new key
  $( "#card-field-id-" + uuid + " .field-key" ).focus();
}

/* Remove a field from the edit pane */
function remove_field(elid) {
  $( "#" + elid ).detach();
}




/* Load the bookmark partial down the LHS */
function populate_bookmark_list() {
  $.get( "/bookmarks", function( data ) {
    $( "#bookmarks" ).html( data );
  });
}


/* Toggle the bookmarked status of the card ID */
function toggle_bookmark(id){

  $.get( "/toggle-bookmark/" + id, function( data ) {

    // The service echoes the ID it has bookmarked,
    // so check this.
    if (data == id){

      var marker = $( ".bookmark-marker-" + js_id(id) );

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


