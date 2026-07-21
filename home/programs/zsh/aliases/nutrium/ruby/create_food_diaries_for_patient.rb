require_relative "support/summary"

# Idempotent: ensures a diary exists for each of the last `food_diaries` days.
# A day that already has a diary is skipped, so re-running tops up missing days
# instead of stacking duplicates.
def create_food_diaries_for_patient(email, food_diaries, filled)
  account = Account.find_by!(email: email)
  patient = account.patient

  created = 0
  skipped = 0

  food_diaries.times do |n|
    date = Date.today - n.days

    if FoodDiary.exists?(patient_id: patient.id, date: date)
      skipped += 1
      next
    end

    food_diary = FoodDiary.new do |food_diary|
      food_diary.patient       = patient
      food_diary.date          = date
      food_diary.created_at    = Time.zone.now - n.days
      food_diary.updated_at    = Time.zone.now - n.days
      food_diary.created_by_id = CreatedBy::PATIENT
    end

    if filled
      as_planned_meal = FoodDiaryMeal.new do |as_planned_meal|
        as_planned_meal.food_diary            = food_diary
        as_planned_meal.meal_type_id          = MealType::BREAKFAST
        as_planned_meal.meal_wrapper_status_id = MealWrapperStatus::FOLLOWS_MEAL_PLAN

        food_diary.food_diary_meals << as_planned_meal
      end
    end

    food_diary.save!
    created += 1
  end

  { patient: patient, created: created, skipped: skipped }
end

email        = ARGV[0]
food_diaries = ARGV[1].to_i
filled       = ARGV[2] == "true"

result  = create_food_diaries_for_patient(email, food_diaries, filled)
patient = result[:patient]

SeedSummary.print("Food Diaries", {
  "Patient"    => "#{patient.name} (#{email})",
  "Created"    => result[:created],
  "Skipped"    => result[:skipped],
  "Date range" => "#{(Date.today - (food_diaries - 1)).iso8601} → #{Date.today.iso8601}",
  "Filled"     => filled
})
