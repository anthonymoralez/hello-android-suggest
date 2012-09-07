package org.example.suggest

import android.app.Activity
import android.app.SearchManager
import android.content.Intent
import android.os.Handler
import android.text.TextWatcher
import android.text.Editable
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.ListView
import android.R.layout as AndroidLayout
import android.util.Log

import java.util.concurrent.Executors
import java.util.ArrayList
import java.util.List
import java.util.concurrent.RejectedExecutionException
import java.lang.InterruptedException

class Suggest < Activity
  class SuggestTextWatcher 
    implements TextWatcher 
    def initialize(outer:Suggest)
      @outer = outer
    end
    def beforeTextChanged(s:CharSequence, start:int, before:int, count:int):void
      #nop
    end
    def onTextChanged(s:CharSequence, start:int, before:int, count:int):void
      Log.d("onTextChanged", "#{s}")
      @outer.queueUpdate(1000)
    end
    def afterTextChanged(e:Editable)
      #nop
    end
  end

  class UpdateTask 
    implements Runnable
    def initialize(outer:Suggest)
      @outer = outer
    end
    def run:void
      original = @outer.origText.getText.toString.trim
      Log.d("UpdateTask", "#{original}")
      @suggPending.cancel(true) if (@suggPending != nil)

      if (original.length != 0)
        @outer.setText(R.string.working)
        begin
          suggestTask = SuggestTask.new(@outer, original)
          @suggPending = @outer.suggThread.submit(suggestTask)
        rescue RejectedExecutionException => e
          @outer.setText(R.string.error)
        end
      end
    end
  end

  def onCreate(state)
    super state
    setContentView R.layout.main
    initThreading
    findViews
    setListeners
    setAdapters
  end

  def origText
    @origText
  end

  def suggThread
    @suggThread
  end

  def initThreading:void
    @guiThread = Handler.new
    @suggThread = Executors.newSingleThreadExecutor
    @updateTask = UpdateTask.new(self) 
  end

  def findViews:void
    @origText = EditText(findViewById(R.id.original_text))
    @suggList = ListView(findViewById(R.id.result_list))
  end

  def setListeners:void
    @origText.addTextChangedListener(SuggestTextWatcher.new(self))
    this = self
    @suggList.setOnItemClickListener do |parent, view, position, id|
      query = String(parent.getItemAtPosition(position))
      this.doSearch(query)
    end
  end

  def setAdapters:void
    @items = ArrayList.new
    @adapter = ArrayAdapter.new(self, AndroidLayout.simple_list_item_1, @items)
    @suggList.setAdapter(@adapter)
  end

  def doSearch(query:String)
    intent = Intent.new(Intent.ACTION_WEB_SEARCH)
    intent.putExtra(SearchManager.QUERY, query)
    startActivity(intent)
  end

  def queueUpdate(delayMillis:long)
    @guiThread.removeCallbacks(@updateTask)
    @guiThread.postDelayed(@updateTask, delayMillis)
  end

  def setText(id:int):void
    @adapter.clear
    @adapter.add(getResources.getString(id))
  end

  def setList(list:List):void
    @adapter.clear
    for item in list
      @adapter.add(item)
    end
  end

  def setSuggestions(suggestions:List):void
    guiSetList(@suggList, suggestions)
  end

  def guiSetList(view:ListView, list:List):void
    this = self
    @guiThread.post do 
      this.setList(list)
    end
  end

end
