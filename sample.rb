raise "Просто кусок кода для примера. Работать не будет."

class User
  def balance=(new_balance); end
  def balance; end
end

# Произвольный запрос к системе.
class Request
  
  # Обработать запрос.
  # Возвращает либо причину отказа, либо объект типа Event в случае успеха и произведения действия.
  # Включает бизнес-логику.
  def process
    raise NotImplementedException
  end
end

# Произвольное событие в системе, вызванное запросом.
class Event
  
  # Бескомпромиссно обрабатывает событие, никакой бизнес-логики, способной вызвать отказ в обработке, не предусматривает. 
  # Возвращает себя же.
  def process
    raise NotImplementedException
  end
end

# Запрос на списание денежных средств.
class BalanceSubtractRequest < Request
  
  def initialize(user, amount) # user -> User, amount -> Float
    self.user = user
    self.amount = amount
  end
  
  def process
    # DO: Бизнес-логика, связанная с решением.
    return { error: "Insufficient funds" } if user.balance < amount
    return { error: "No payments at night" } if (0..7).include?(Time.now)
    # DO: Действие.
    BalanceSubtractEvent.new(user, amount).process
  end
  
end

# Событие списания денежных средств.
class BalanceSubtractEvent < Event
  
  def initialize(user, amount) # user -> User, amount -> Float
    self.user = user
    self.amount = amount
    self.processed = false
  end
  
  # Обрабатывает списание денег со счета.
  def process
    User.balance -= self.amount
    self.processed = true
    self
  end
  
  # Возвращает объект для сериализации.
  def serialize
    {
      user: user.id,
      amount: amount
      processed: processed
    }
  end

  # Возвращает десериализованный объект.
  def self.deserialize(memento)
    new(User.find(memento[:id]), memento[:amount])
  end
  
end

# Отвечает за сериализацию событий так или иначе. Например, за отправку их в очередь.
class EventSerializer
  
  # Метод, сериализующий передаваемый ему hash.
  def serialize(event) # event -> Event
    # DO: Отправляем событие в очередь.
    Queue.append { klass: event.class.to_s, parameters: event.serialize }
  end
  
end

# Списываем деньги с пользователя:

user = User.find('6F9619FF-8B86-D011-B42D-00CF4FC964FF')
