# The API outputs of Muffinland, put in a separate file for easier maintenance
class Muffinland

  def mlResponse_for_EmptyDB
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
            @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts.map{|req|req.inspect}
    }
  end

  def mlResponse_for_GET_muffin( muffin )
    mlResponse = {
        :out_action => "GET_named_page",
        :muffin_id => muffin.id,
        :muffin_body => muffin.raw,
        :tags => muffin.dangerously_all_tags,
        :dangerously_all_muffins_raw =>
            @theBaker.dangerously_all_muffins.map{|muff|muff.raw},
        :dangerously_all_posts =>
            @theHistorian.dangerously_all_posts.map{|req|req.inspect}
    }
  end

end

