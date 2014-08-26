# The API outputs of Muffinland, put in a separate file for easier maintenance
class Muffinland

  def ml_response_for_EmptyDB
    mlResponse = { :out_action => "EmptyDB" }
  end

  def mlResponse_for_UnregisteredCommand
    mlResponse = { :out_action => "Unregistered Command" }
  end

  def mlResponse_for_404_basic( request )
    mlResponse = {
        :out_action => "404",
        :requested_name => request.name_from_path,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.for_viewing},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts#.map{|req|req.inspect}
    }
  end

  def mlResponse_for_GET_muffin( muffin )
    mlResponse = {
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

