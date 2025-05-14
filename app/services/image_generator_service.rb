require 'mini_magick'
require 'open-uri'

class ImageGeneratorService
  def self.generate(submission)
    logger = Rails.logger
    
    if submission.nil?
      logger.error "Submission is nil"
      return nil
    end

    if submission.generated_image_path.present?
      logger.info "Image already generated for submission #{submission.uuid}"
      return submission.generated_image_path
    end

    # Ensure output directory exists
    output_dir = Rails.root.join("public/generated")
    FileUtils.mkdir_p(output_dir)
    logger.info "Ensuring output directory exists: #{output_dir}"

    begin
      logger.info "Starting image generation for submission #{submission.uuid}"
      # Create a blank canvas with a white background
      canvas = MiniMagick::Image.create("1200x630", "xc:white") { |i| i.format "png" }

      logger.info "Processing book covers for submission #{submission.uuid}"
      submission.submission_books.order(:book_order).map.with_index do |book, index|
        begin
          logger.info "Processing book #{index + 1}: #{book.title}"
          # Download and process cover image
          cover = MiniMagick::Image.open(book.cover_url)
          logger.info "Successfully downloaded cover image for book #{index + 1}"
          cover.resize "300x450"
          
          # Calculate x position
          x_offset = case index
            when 0 then 150    # Left
            when 1 then 450    # Center
            when 2 then 750    # Right
          end
          
          # Composite the cover onto the canvas
          logger.info "Compositing book #{index + 1} at offset #{x_offset}"
          canvas = canvas.composite(cover) do |c|
            c.compose "Over"
            c.geometry "+#{x_offset}+90"
          end
          logger.info "Successfully composited book #{index + 1}"
          
        rescue => e
          logger.error "Failed to process book #{index + 1}: #{e.message}"
          logger.error e.backtrace.join("\n")
          # Create a placeholder for failed covers
          placeholder = MiniMagick::Image.create("300x450", "xc:lightgray") do |i|
            i.format "png"
            i.gravity "center"
            i.pointsize "24"
            i.draw "text 0,0 'No Image'"
          end

          canvas = canvas.composite(placeholder) do |c|
            c.compose "Over"
            c.geometry "+#{x_offset}+90"
          end
        end
      end

      # Add hashtag
      caption = MiniMagick::Image.create("600x100", "xc:transparent") do |i|
        i.format "png"
        i.gravity "center"
        i.pointsize "36"
        i.font "Arial"
        i.fill "#333333"
        i.draw "text 0,0 '#3books-changed-me'"
      end

      canvas = canvas.composite(caption) do |c|
        c.compose "Over"
        c.gravity "south"
        c.geometry "+0+50"
      end

      # Save the final image
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      filename = "submission_#{submission.uuid}_#{timestamp}.jpg"
      output_path = Rails.root.join("public/generated/#{filename}")
      logger.info "Saving image to #{output_path}"
      
      begin
        canvas.write(output_path)
        logger.info "Successfully saved image"

        # Update submission with the image path
        logger.info "Updating submission record with image path"
        submission.update!(generated_image_path: "/generated/#{filename}")
        logger.info "Successfully updated submission record"
        
        "/generated/#{filename}"
      rescue => e
        logger.error "Failed to save image or update record: #{e.message}"
        logger.error e.backtrace.join("\n")
        File.unlink(output_path) if File.exist?(output_path)
        nil
      end
    rescue => e
      logger.error "Failed to generate combined image: #{e.message}"
      logger.error e.backtrace.join("\n")
      nil
    end
  end
end
