# encoding: UTF-8

require 'bundler'
Bundler.require

# Подготовимся...

class String
  include Term::ANSIColor
end

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

ActiveRecord::Schema.define do
  create_table :posts, :force => true do |t|
    t.string :author
    t.string :title
    t.timestamps
  end
end

# Создадим модели...

class Post < ActiveRecord::Base
  validate :ensure_author_is_not_a_spammer
  
  def ensure_author_is_not_a_spammer
    errors.add(:base, "Спаммерам нельзя публиковаться в блоге") if author == "Spammer"
  end
end

# ===================================
# Здесь начинается событийная система
# ===================================

# Просто, чтобы были, на самом деле, конечно, их определение полнее
class Event; end   
class Request; end

# Запрос на создание новой публикации.
class NewPostRequest < Request
  def initialize(author, title)
    @author = author
    @title = title
  end
  
  def process
    puts "[REQUEST] Делаем запрос на публикацию от #{@author} с текстом: '#{@title}'".cyan
    post = Post.new(author: @author, title: @title)
    return post.errors.map { |field, error| error }.join(",") unless post.valid?
    NewPostEvent.new(@author, @title)
  end
end

# Событие создания новой публикации.
class NewPostEvent < Event
  def initialize(author, title)
    puts "[EVENT] Создаем событие публикации от #{author} с текстом: '#{title}'".cyan
    @post = Post.new(author: author, title: title)
  end

  def process!
    @post.save!
    puts "[EVENT] Публикация создана!".green
    true
  end 
end

# СОЗДАДИМ ПОСТЫ

# Функция удобной обработки запроса и вывода на экран его результатов.
# К системе не относится.
def process_post_request(post_request)
  post_event = post_request.process
  if post_event.kind_of?(Event)
    post_event.process!
  else
    puts "Ошибка при создании публикации: #{post_event}".red
  end
end

puts "\nСОЗДАЕМ ПОСТЫ ЗАПРОСАМИ\n".cyan

# Неудачно:
post_request = NewPostRequest.new("Spammer", "Бла-бла, Виагра")
process_post_request(post_request)

# Удачно:
post_request = NewPostRequest.new("Вася", "Бла-бла, хороший пост")
process_post_request(post_request)

puts "\nСОЗДАЕМ ПОСТЫ ЧЕРЕЗ ПЛЕЕР (ВОСПРОИЗВОДИМ ПРОШЛЫЕ СОБЫТИЯ)\n".cyan

# Неудачно. Такого события попасть в список событий не могло, т.к. оно бы отсеялось 
# бизнес-логикой (т.е. валидацией в нашем случае) в NewPostRequest. Единственный
# вариант, когда это может произойти, это если мы вдруг пересмотрели свою политику
# относительно обработки спама. В этом случае нужно придумывать, каким образом мы
# будем обрабатывать события, оставленные спаммерами, отдельно. Например, можно
# игнорировать такие события.
begin
  post_event = NewPostEvent.new("Spammer", "Пишем через плеер, бла-бла, Виагра")
  post_event.process!
rescue ActiveRecord::RecordInvalid => ex
  puts "Не удалось создать запись: #{ex.to_s}".red
end

post_event = NewPostEvent.new("Федя", "Пишем через плеер, нормальный пост")
post_event.process!

# И выведем результаты:
puts "\nСозданные посты:".cyan
Post.all.each_with_index do |post, idx|
  puts "    #{idx+1}. #{post.author} написал: '#{post.title}'".cyan
end
