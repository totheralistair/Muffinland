# The API outputs of Muffinland, put in a separate file for easier maintenance
class Muffinland

  def ml_response_for_EmptyDB
    ml_response = { :out_action => "EmptyDB" }
  end

  def ml_response_for_UnregisteredCommand
    ml_response = { :out_action => "Unregistered Command" }
  end

  def ml_response_for_404_basic( request )
    ml_response = {
        :out_action => "404",
        :requested_name => request.name_from_path,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.for_viewing},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

  def ml_response_for_GET_muffin( muffin )
    ml_response = {
        :out_action => "GET_named_page",
        :muffin_id => muffin.id,
        :muffin_content_type => muffin.content_type,
        :muffin_body => muffin.for_viewing,
        :belongs_to_collections => muffin.belongs_to_collections_ids,
        :muffin_is_collection => muffin.collection?,
        :all_muffins_collected_ids => muffin.all_collected_muffins_ids,
        :all_collection_muffin_ids =>
            @theBaker.all_collection_muffin_ids,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.for_viewing},
#        :dangerously_all_posts =>
#            @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

end

