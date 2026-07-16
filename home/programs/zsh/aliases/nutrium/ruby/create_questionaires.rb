questionaries_file      = File.join(Rails.root, 'data/templates/nutrium/questionaries.yml')
questionaries_templates = YAML.load_file(questionaries_file)
patient_info_types      = PatientInfoType.all

puts "Size: #{questionaries_templates.size}"

ActiveRecord::Base.transaction do
  questionaries_templates.map do |questionary|
    puts '[Questionary]'
    questionary_exists =
      Questionary.where(
        template_source_id: questionary['template_source_id'],
        template_language_id: questionary['template_language_id'],
        template_category_id: questionary['template_category_id']
      ).exists?

    next if questionary_exists

    questionary_to_save = Questionary.create!(questionary.except('questionary_questions'))

    questionary['questionary_questions'].each do |questionary_question|
      if questionary_question['measurement_type_id'] || questionary_question['code']
        questionary_question_to_save = QuestionaryQuestion.new(questionary_question)
      else
        patient_info_type = patient_info_types.find_by!(code: questionary_question['patient_info_type_code'])

        questionary_question_to_save = QuestionaryQuestion.new(
          patient_info_type_id: patient_info_type.id,
          questionary_question_category_id: questionary_question['questionary_question_category_id'],
          questionary_question_value_type_id: questionary_question['questionary_question_value_type_id']
        )
      end

      questionary_question_to_save.questionary = questionary_to_save
      puts 'Saving questionary'
      questionary_question_to_save.save!
    end
  end
end
