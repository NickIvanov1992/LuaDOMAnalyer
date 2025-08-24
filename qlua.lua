---@meta
---@class QLua
---Глобальный объект QLua, предоставляемый средой QUIK.
qlua = {}

--#region Классы данных

---@class Quote
---@field class_code string Класс бумаги
---@field sec_code string Код бумаги
---@field bid number Лучшая цена покупки
---@field ask number Лучшая цена продажи
---@field bid_quantity number Количество по лучшей цене покупки
---@field ask_quantity number Количество по лучшей цене продажи

---@class Candle
---@field open number Цена открытия
---@field close number Цена закрытия
---@field high number Максимальная цена
---@field low number Минимальная цена
---@field volume number Объем
---@field datetime table Дата и время свечи {year, month, day, hour, min, sec}

---@class Trade
---@field trade_num number Номер сделки
---@field class_code string Класс бумаги
---@field sec_code string Код бумаги
---@field price number Цена сделки
---@field qty number Количество бумаг в сделке
---@field datetime table Дата и время сделки

---@class Order
---@field order_num number Номер заявки в QUIK
---@field class_code string Класс бумаги
---@field sec_code string Код бумаги
---@field operation string Операция: "B" - покупка, "S" - продажа
---@field price number Цена заявки
---@field qty number Количество лотов
---@field balance number Неисполненный остаток
---@field state string Состояние заявки

---@field datetime table Дата и время заявки

---@class StopOrder : Order
---@field stop_order_type string Тип стоп-заявки

---@class AccountPosition
---@field asset_code string Код актива
---@field open_balance number Входящий остаток
---@field current_pos Текущая позиция
---@field planned_pos Плановая позиция

---@class DepoLimit
---@field sec_code string Код бумаги
---@field current_balance number Текущий остаток
---@field limit_kind string Тип лимита

---@class MoneyLimit
---@field curr_code string Код валюты
---@field current_balance number Текущий остаток
---@field limit_kind string Тип лимита

---@class ParamRequestResult
---@field class_code string
---@field sec_code string
---@field result boolean
---@field error_msg string

---@class TransactionReply
---@field trans_id number ID транзакции
---@field status number Статус выполнения
---@field result_msg string Сообщение
---@field uid number UID транзакции

--#endregion

--#region Основные функции

---Отправить сообщение в окно сообщений QUIK
---@param message string Текст сообщения
---@param icon_type number? Тип иконки (1-инфо, 2-предупреждение, 3-ошибка). По умолчанию 1.
function qlua.message(message, icon_type) end

---Проверить соединение с сервером QUIK
---@return boolean connected True если подключение установлено
function qlua.isConnected() end

---Получить текущую дату и время сервера
---@return table datetime Таблица {year, month, day, hour, min, sec, ms}
function qlua.getInfoParam("SERVERTIME") end

---Получить параметр из информации о подключении
---@param param_name string Имя параметра
---@return string value Значение параметра
function qlua.getInfoParam(param_name) end

--#endregion

--#region Функции для работы с данными

---Подписаться на получение обновлений стакана котировок
---@param class_code string Класс бумаги
---@param sec_code string Код бумаги
function qlua.Subscribe_Level_II_Quotes(class_code, sec_code) end

---Отписаться от получения обновлений стакана котировок
---@param class_code string Класс бумаги
---@param sec_code string Код бумаги
function qlua.Unsubscribe_Level_II_Quotes(class_code, sec_code) end

---Получить текущие котировки по бумаге
---@param class_code string Класс бумаги
---@param sec_code string Код бумаги
---@return Quote quote Объект котировки
function qlua.getQuote(class_code, sec_code) end

---Запросить параметры бумаги
---@param class_code string Класс бумаги
---@param sec_code string Код бумаги
---@return ParamRequestResult result Результат запроса
function qlua.getParamEx(class_code, sec_code, param_name) end

---Получить свечу по индексу
---@param tag string Идентификатор графика
---@param line number Номер линии индикатора (0 для ценового графика)
---@param index number Индекс свечи (0 - последняя свеча)
---@return Candle candle Объект свечи
---@return string error Описание ошибки, если есть
function qlua.getCandle(tag, line, index) end

---Получить количество свечей в графике
---@param tag string Идентификатор графика
---@param line number Номер линии индикатора
---@return number size Количество свечей
function qlua.Size(tag, line) end

--#endregion

--#region Функции для работы с заявками и транзакциями

---Создать новую транзакцию
---@param t table Параметры транзакции
---@return number trans_id ID транзакции
function qlua.sendTransaction(t) end

---Получить список заявок
---@return table orders Таблица с объектами Order
function qlua.getOrders() end

---Получить список стоп-заявок
---@return table stop_orders Таблица с объектами StopOrder
function qlua.getStopOrders() end

---Получить список сделок
---@return table trades Таблица с объектами Trade
function qlua.getTrades() end

---Получить лимиты по денежным средствам
---@return table money_limits Таблица с объектами MoneyLimit
function qlua.getMoneyLimits() end

---Получить лимиты по бумагам
---@return table depo_limits Таблица с объектами DepoLimit
function qlua.getDepoLimits() end

---Получить позиции по счету
---@return table account_positions Таблица с объектами AccountPosition
function qlua.getPortfolioInfo(exclude_zero) end

--#endregion

--#region Callback функции (события)

---Callback-функция при подключении/отключении терминала QUIK
---@param is_connected boolean Статус подключения
function main.OnConnected(is_connected) end

---Callback-функция при изменении стакана котировок
---@param class_code string Класс бумаги
---@param sec_code string Код бумаги
function main.OnQuote(class_code, sec_code) end

---Callback-функция при изменении свечи на графике
---@param tag string Идентификатор графика
---@param line number Номер линии индикатора
---@param index number Индекс изменившейся свечи
function main.OnCandle(tag, line, index) end

---Callback-функция при изменении заявки
---@param order Order Объект заявки
function main.OnOrder(order) end

---Callback-функция при изменении стоп-заявки
---@param stop_order StopOrder Объект стоп-заявки
function main.OnStopOrder(stop_order) end

---Callback-функция при появлении новой сделки
---@param trade Trade Объект сделки
function main.OnTrade(trade) end

---Callback-функция при изменении лимитов по денежным средствам
---@param money_limit MoneyLimit Объект лимита
function main.OnMoneyLimit(money_limit) end

---Callback-функция при изменении лимитов по бумагам
---@param depo_limit DepoLimit Объект лимита
function main.OnDepoLimit(depo_limit) end

---Callback-функция при ответе на транзакцию
---@param reply TransactionReply Ответ транзакции
function main.OnTransReply(reply) end

--#endregion

--#region Константы (наиболее используемые)

---Типы операций
qlua.OPERATION_BUY = "B"
qlua.OPERATION_SELL = "S"

---Типы стоп-заявок
qlua.STOP_ORDER_TYPE_LIMIT = "L"
qlua.STOP_ORDER_TYPE_CONDITION = "C"

---Статусы заявок
qlua.ORDER_ACTIVE = "Active"
qlua.ORDER_COMPLETED = "Completed"
qlua.ORDER_CANCELED = "Canceled"

---Иконки для сообщений
qlua.ICON_INFO = 1
qlua.ICON_WARNING = 2
qlua.ICON_ERROR = 3

---Параметры для getInfoParam
qlua.INFO_PARAM_SERVER_TIME = "SERVERTIME"
qlua.INFO_PARAM_CONNECTION = "CONNECTION"
qlua.INFO_PARAM_STATUS = "STATUS"
qlua.INFO_PARAM_CLIENT_CODE = "CLIENT_CODE"
qlua.INFO_PARAM_TRADE_DATE = "TRADEDATE"

---Параметры для getParamEx (примеры)
qlua.PARAM_PRICE = "PRICE"
qlua.PARAM_LAST = "LAST"
qlua.PARAM_BID = "BID"
qlua.PARAM_ASK = "ASK"
qlua.PARAM_LOTSIZE = "LOTSIZE"
qlua.PARAM_LOTSize = "LOTSIZE"
qlua.PARAM_MINPRICE = "MINPRICE"
qlua.PARAM_MAXPRICE = "MAXPRICE"
qlua.PARAM_VOLATILITY = "VOLATILITY"
qlua.PARAM_STEPPRICE = "STEPPRICE"

--#endregion

---@class Table
---@field [integer] any

---@class fun(...): any

---Функция вывода в лог (аналог print)
---@param ... any
function print(...) end

---Функция форматированного вывода (аналог string.format)
---@param format string
---@param ... any
---@return string
function string.format(format, ...) end

---Текущий обработчик (для колбэков)
main = {}
