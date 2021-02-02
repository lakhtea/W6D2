require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @cols == nil
      cols = DBConnection.execute2(<<-SQL)
        SELECT
          *
        FROM
          "#{table_name}"
      SQL
      @cols = cols.first.map { |col| col.to_sym }
      @cols
    else
      @cols
    end
  end

  def self.finalize!
    cols = self.columns
    cols.each do |col|
      define_method(col) { self.attributes[col] }
      define_method("#{col}=") { |value = nil| self.attributes[col] = value }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT 
        *
      FROM 
        #{table_name}
    SQL
    self.parse_all(rows)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    object = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ? 
    SQL

    self.parse_all(object).first
  end

  def initialize(params = {})
    class_name = self.class
    cols = class_name.columns
    params.each do |item, value|
      item = item.to_sym
      if !cols.include?(item)
        raise "unknown attribute '#{item}'"
      else
        self.send("#{item}=", value)
      end 
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| self.send(col) }
  end

  def insert
    col_names = self.class.columns.join(",")
    question_marks = (["?"] * (self.class.columns.length)).join(",")
    new_record = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    
  end

  def save
    # ...
  end
end
