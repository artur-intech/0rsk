# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2019-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'rsk'
require_relative 'cause'
require_relative 'query'

# Causes.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2019-2025 Yegor Bugayenko
# License:: MIT
class Rsk::Causes
  def initialize(pgsql, project)
    @pgsql = pgsql
    @project = project
  end

  def add(text)
    @pgsql.transaction do |t|
      id = t.exec(
        'INSERT INTO part (project, text, type) VALUES ($1, $2, $3) RETURNING id',
        [@project, text, 'Cause']
      )[0]['id'].to_i
      t.exec('INSERT INTO cause (id) VALUES ($1)', [id])
      id
    end
  end

  def emojis
    found = @pgsql.exec(
      [
        'SELECT DISTINCT emoji FROM cause',
        'JOIN part ON part.id = cause.id',
        'WHERE project = $1'
      ],
      [@project]
    ).map { |r| r['emoji'] }
    (found + ['💰', '💾', '🏢', '🤵', '📚', '📦']).uniq
  end

  def get(id)
    require_relative 'cause'
    Rsk::Cause.new(@pgsql, id)
  end

  def count(query: '')
    query(query).count
  end

  def fetch(query: '', limit: 10, offset: 0)
    query(query).fetch(offset, limit).map do |r|
      {
        id: r['id'].to_i,
        text: r['text'],
        emoji: r['emoji'],
        rank: r['rank'].to_i,
        risks: r['risks'].to_i
      }
    end
  end

  private

  def query(query)
    Rsk::Query.new(
      @pgsql,
      [
        'SELECT cause.*, part.text,',
        '  SUM(risk.probability * effect.impact) / COUNT(risk.id) AS rank,',
        '  COUNT(risk.id) AS risks',
        'FROM cause',
        'JOIN part ON part.id = cause.id',
        'LEFT JOIN triple ON triple.cause = cause.id',
        'LEFT JOIN risk ON triple.risk = risk.id',
        'LEFT JOIN effect ON triple.effect = effect.id',
        'WHERE project = $1 AND (LOWER(text) LIKE $2 OR emoji LIKE $2)',
        'GROUP BY cause.id, part.id',
        'ORDER BY rank DESC'
      ],
      [@project, "%#{query.to_s.downcase.strip}%"]
    )
  end
end
