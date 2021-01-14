require "digest"

RSpec.describe "Terraform consistency" do
  describe "app deployments" do
    it "should have consistent versions.tf files" do
      variables_files = Dir.glob('terraform/deployments/apps/*/versions.tf')
      variables_files_by_content = variables_files.group_by {|path| Digest::SHA256.file(path).base64digest }

      expect(variables_files_by_content.length).to eq(1), <<~MESSAGE
      Expected all versions.tf files in terraform/deployments/apps to have the same content,
      but found #{variables_files_by_content.length} different groups:

      ---

        #{variables_files_by_content.map{|group, values| values.join("\n  ") }.join("\n\n---\n\n  ")}

      ---
      MESSAGE
    end

    # TODO: Enable this test once the app deployments are consistent
    xit "should have consistent variables.tf files" do
      variables_files = Dir.glob('terraform/deployments/apps/*/variables.tf')
      variables_files_by_content = variables_files.group_by {|path| Digest::SHA256.file(path).base64digest }

      expect(variables_files_by_content.length).to eq(1), <<~MESSAGE
      Expected all variables.tf files in terraform/deployments/apps to have the same content,
      but found #{variables_files_by_content.length} different groups:

      ---

        #{variables_files_by_content.map{|group, values| values.join("\n  ") }.join("\n\n---\n\n  ")}

      ---
      MESSAGE
    end

  end
end