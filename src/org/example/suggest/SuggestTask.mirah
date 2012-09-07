package org.example.suggest

import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.LinkedList
import java.util.concurrent.RejectedExecutionException
import java.lang.InterruptedException
import java.lang.Thread
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserException
import android.util.Log
import android.util.Xml


class SuggestTask 
  implements Runnable

  def initialize(context:Suggest, original:String)
    @suggest = context
    @original = original
  end

  def run:void
    suggestions = suggest(@original)
    @suggest.setSuggestions(suggestions)
  end
  
  def con:HttpURLConnection
    HttpURLConnection(@con)
  end

  def suggest(original:String)
    messages = LinkedList.new
    error = nil
    @con = nil

    begin 
      raise InterruptedException.new if (Thread.interrupted)

      Log.d("SuggestTask", original)
      q = URLEncoder.encode(original, "UTF-8")
      url = URL.new("http://google.com/complete/search?output=toolbar&q=#{q}")

      @con = HttpURLConnection(url.openConnection)
      con.setReadTimeout(10000)#ms
      con.setConnectTimeout(15000)#ms
      con.setRequestMethod("GET")
      con.addRequestProperty("Referer", "http://www.pragprog.com/titles/eband3/hello-android")
      con.setDoInput(true)

      Log.d("SuggestTask", "connecting")
      con.connect
      Log.d("SuggestTask", "connected")
      
      raise InterruptedException.new if (Thread.interrupted)

      Log.d("SuggestTask", "parsing")
      parser = Xml.newPullParser
      parser.setInput(con.getInputStream, nil)
      eventType = parser.getEventType
      while (eventType != XmlPullParser.END_DOCUMENT) 
        name = parser.getName
        if (eventType == XmlPullParser.START_TAG && name.equalsIgnoreCase("suggestion"))
          Log.d("SuggestTask", "suggestion")
          i = 0
          while i < parser.getAttributeCount
            if (parser.getAttributeName(i).equalsIgnoreCase("data"))
              Log.d("SuggestTask", "suggestion: #{parser.getAttributeValue(i)}")
              messages.add(parser.getAttributeValue(i)) 
            end 
            i+=1
          end
        end
        eventType = parser.next
      end
      Log.d("SuggestTask", "parsed")
      raise InterruptedException.new if (Thread.interrupted)
    rescue IOException => e
      error = @suggest.getResources.getString(R.string.error) + " #{e.toString}"
    rescue XmlPullParserException => e
      error = @suggest.getResources.getString(R.string.error) + " #{e.toString}"
    rescue InterruptedException => e
      error = @suggest.getResources.getString(R.string.interrupted) + " #{e.toString}"
    ensure  
      con.disconnect if con != nil
    end

    if (error != nil)
      Log.d("SuggestTask", error)
      messages.clear
      messages.add(error)
    end

    messages.add(@suggest.getResources.getString(R.string.no_results)) if (messages.size == 0)
    Log.d("SuggestTask", "suggestions = #{messages.toString}")
    messages
  end
end
