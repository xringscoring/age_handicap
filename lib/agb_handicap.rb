module AgbHandicap

  SCORING_SCHEMES = {
    'METRIC' => 'Standard WA target face 10 -1',
    'IMPERIAL' => 'Standard WA target face 9 - 1',
    'INNER_TEN' => 'Standard WA target face 10-1 with x-ring counting as 10, eg compound scoring',
    'TRIPLE' => 'Standard 3-spot 5-zone WA target face, eg WA18m round',
    'TRIPLE_INNER_TEN' => 'Standard 3-spot 5-zone WA target face with x-ring counting as 10, eg compound WA18m round',
    'ONE_TO_FIVE' => '5-zone scoring, eg Worcester, NFAA Indoor',
    'SIX_ZONE' => '6-zone WA target face, eg compound 50m'
  }

  class << self

    # score = integer
    # distances = [ {'range_in_meters' => 18, 'total_shots' => 60, 'target_diameter_cm' => 40, 'scoring_scheme' => 'METRIC'} ]
    def calculate(score, distances, rounded = true)
      result = agbhandicap(score, distances)
      if rounded
        result = result.ceil.to_i
      end
      result
    end

    private

    def agbhandicap(score, distances)
      rtrange = 32.0
      hc = 50.0

      while (rtrange > 0.01)
        nextscore = agbscore(hc, distances)

        if (score < nextscore)
          hc = hc + rtrange
        end

        if (score > nextscore)
          hc = hc - rtrange
        end

        rtrange = rtrange / 2
      end

      hc = 0 if (hc < 0)
      hc = 100 if (hc > 100)

      return hc.to_f.round(1)
    end

    def agbscore(h, distances)
      score = 0.0
      distances.each do | d |
        score = score + calculate_distance_score(d, h)
      end
      score
    end

    def calculate_distance_score(distance, h)
      range = distance['range_in_meters'].to_f
      shots = distance['total_shots'].to_f
      diameter = distance['target_diameter_cm'].to_f
      scoring = distance['scoring_scheme']

      score = 0
      sr = score_range(h, range)

      case scoring
      when 'METRIC'
        score = 10
        (1..10).each do | n |
          score = score - solution( (n.to_f * diameter / 20.0 + 0.357), sr.to_f)
        end
      when 'IMPERIAL'
        score = 9
        (1..4).each do | n |
          score = score - (2.0 * solution( (n.to_f * diameter / 10.0 + 0.357), sr.to_f ))
        end
        score = score - solution( (diameter / 2 + 0.357), sr.to_f )
      when 'ONE_TO_FIVE' # could be worcester or NFAA round etc
        score = 5
        (1..5).each do | n |
          score = score - solution( (n.to_f * diameter / 10.0 + 0.357), sr.to_f )
        end
      when 'INNER_TEN'
        score = 10
        score = score - solution( (diameter / 40 + 0.357), sr.to_f )
        (2..10).each do | n |
          score  = score - solution( (n.to_f * diameter / 20 + 0.357), sr.to_f )
        end
      when 'TRIPLE'
        score = 10
        (1..4).each do | n |
          score = score - solution( (n.to_f * diameter / 20 + 0.357), sr.to_f )
        end
        score = score - (6 * solution( (5 * diameter / 20 + 0.357), sr.to_f ))
      when 'TRIPLE_INNER_TEN'
        score = 10
        score = score - solution( (diameter / 40 + 0.357), sr.to_f )
        (2..4).each do | n |
          score = score - solution( (n.to_f * diameter / 20 + 0.357), sr.to_f )
        end
        score = score - (6 * solution( (5 * diameter / 20 + 0.357), sr.to_f ))
      when 'SIX_ZONE' # WA 50M Compound
        score = 10
        (1..5).each do | n |
          score = score - solution( (n.to_f * diameter / 20 + 0.357), sr.to_f )
        end
        score = score - (5 * solution( (6 * diameter / 20 + 0.357), sr.to_f ))
      end

      (score.to_f * shots.to_f).to_f
    end

    def score_range(h, range)
      100 * range * (1.036 ** (h.to_f + 12.9)) * 5e-4 * (1 + 1.429e-6 * (1.07 ** (h.to_f + 4.3)) * (range * range))
    end

    def solution(operator, score_range)
      return Math.exp( -(operator / score_range) ** 2 )
    end

  end # end class
end
