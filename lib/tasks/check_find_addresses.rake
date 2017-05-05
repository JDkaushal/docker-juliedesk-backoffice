task :check_find_addresses => :environment do
  options = {}
  o = OptionParser.new do |opts|
    opts.on("-f", "--filename ARG", String) { |arg| options[:filename] = arg }
    opts.on("-m", "--method ARG", String) { |arg| options[:method_to_check] = arg }
    opts.on("-n", "--print-name-diff ARG", String) { |arg| options[:print_name_diff] = arg }
    opts.on("-e", "--print-email-diff ARG", String) { |arg| options[:print_email_diff] = arg }
  end
  args = o.order!(ARGV) {}
  o.parse!(args)

  old_method, new_method = :original_find_addresses, options[:method_to_check].to_sym
  email_diff = []
  name_diff = []
  score_for_emails = 0
  score_for_names = 0

  File.open(options[:filename]).each_with_index do |line, i |
    puts "#{i} entries processed" if i%1000 == 0 && i > 0
    fields_to_parse = line.split(';')
    fields_to_parse.each do |field|
      next if field.empty?
      addresses = ApplicationHelper.send(old_method, field).addresses
      emails = addresses.map(&:address).map(&:downcase).sort
      names = addresses.map(&:name)

      new_addresses = ApplicationHelper.send(new_method, field).addresses
      new_emails = new_addresses.map(&:address).map(&:downcase).sort
      new_names = new_addresses.map(&:name)

      email_diff << field if emails != new_emails
      score_for_emails -= (emails - new_emails).length

      name_diff << field if names != new_names
      score_for_names -= (names - new_names).length
    end
  end

  puts "Email Score: #{score_for_emails}"
  puts "Name Score: #{score_for_names}"

  if options[:print_name_diff] == 'yes'
    puts "\nName Diff: "
    puts name_diff.join("\n")
  end

  if options[:print_email_diff] == 'yes'
    puts "\nEmail Diff: "
    puts email_diff.join("\n")
  end
end

