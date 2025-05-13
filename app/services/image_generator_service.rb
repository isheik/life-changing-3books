require 'mini_magick'
require 'open-uri'

class ImageGeneratorService
  def self.generate(submission)
    return if submission.nil? || submission.generated_image_path.present?

    # Ensure output directory exists
    FileUtils.mkdir_p(Rails.root.join("public/generated"))

    begin
      # Create a blank canvas
      canvas = MiniMagick::Image.new(MiniMagick::Tool::Convert.new do |convert|
        convert.size "1200x630"
        convert.xc "white"
      end.call)

      # Process each book cover
      covers = submission.submission_books.order(:book_order).map.with_index do |book, index|
        begin
          # Download and process cover image
          cover = MiniMagick::Image.open(book.cover_url)
          cover.resize "300x450"
          
          # Calculate x position
          x_offset = case index
            when 0 then 150    # Left
            when 1 then 450    # Center
            when 2 then 750    # Right
          end
          
          # Composite the cover onto the canvas
          canvas = canvas.composite(cover) do |c|
            c.compose "Over"
            c.geometry "+#{x_offset}+90"
          end
          
        rescue => e
          Rails.logger.error "Failed to process book cover: #{e.message}"
          # Create a placeholder for failed covers
          placeholder = MiniMagick::Image.new(MiniMagick::Tool::Convert.new do |convert|
            convert.size "300x450"
            convert.xc "lightgray"
            convert << "caption:No Image"
            convert.gravity "center"
            convert.composite
          end.call)

          canvas = canvas.composite(placeholder) do |c|
            c.compose "Over"
            c.geometry "+#{x_offset}+90"
          end
        end
      end

      # Add hashtag
      canvas = canvas.composite(MiniMagick::Image.new(MiniMagick::Tool::Convert.new do |convert|
        convert << "caption:#3books-changed-me"
        convert.font "Arial"
        convert.pointsize "36"
        convert.fill "#333333"
        convert.gravity "center"
      end.call)) do |c|
        c.geometry "+0+250"
      end

      # Save the final image
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      filename = "submission_#{submission.uuid}_#{timestamp}.jpg"
      output_path = Rails.root.join("public/generated/#{filename}")
      canvas.write(output_path)

      # Update submission with the image path
      submission.update!(generated_image_path: "/generated/#{filename}")
      
      "/generated/#{filename}"
    rescue => e
      Rails.logger.error "Failed to generate combined image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end
  end
end
