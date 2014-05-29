$(function() {
  var cache = {};
  $( "#search" ).autocomplete({
    minLength: 2,
    source: function( request, response ) {
        var term = request.term;
        if ( term in cache ) {
          response( cache[ term ] );
          return;
        }

        $.getJSON( "/search", request, function( data, status, xhr ) {
          cache[ term ] = data;
          response( data );
        });
      },
    select: function( event, ui ) {
        alert("Selected!");
      }
    });
});

