require 'mini_magick'
require 'open-uri'

class ImageGeneratorService
  def self.generate(submission)
    return if submission.nil? || submission.generated_image_path.present?

    # Create a base image with white background
    base_image = MiniMagick::Image.create("1200x630") do |b|
      b.background "white"
      b.format "jpg"
    end

    # Download and process each book cover
    book_images = []
    submission.submission_books.order(:book_order).each do |book|
      begin
        # Download and resize book cover
        temp_image = MiniMagick::Image.open(book.cover_url)
        temp_image.resize "300x450"
        book_images << temp_image
      rescue => e
        Rails.logger.error "Failed to process book cover: #{e.message}"
        # Create a plain placeholder for failed covers
        temp_image = MiniMagick::Image.create("300x450") do |b|
          b.background "#f3f4f6"  # Tailwind gray-100
          b.format "jpg"
        end
        book_images << temp_image
      end
    end

    begin
      # Combine images horizontally with padding
      result = base_image
      result.combine_options do |c|
        c.gravity "center"
        
        # Calculate positions for 3 books
        x_positions = [-350, 0, 350]
        book_images.each_with_index do |book_image, index|
          # Add each book cover to the base image
          c.draw "image Over #{x_positions[index]},-50 0,0 '#{book_image.path}'"
        end
        
        # Add hashtag
        c.font "Arial"
        c.pointsize "36"
        c.fill "#333333"
        c.draw "text 0,250 '#3books-changed-me'"
      end

      # Save the generated image
      timestamp = Time.current.strftime("%Y%m%d%H%M%S")
      filename = "submission_#{submission.uuid}_#{timestamp}.jpg"
      
      # Ensure directory exists
      FileUtils.mkdir_p(Rails.root.join("public/generated"))
      image_path = Rails.root.join("public/generated/#{filename}")
      
      # Write the final image
      result.format "jpg"
      result.write(image_path)

      # Clean up temporary files
      book_images.each do |book_image|
        FileUtils.rm_f(book_image.path) if book_image.path && File.exist?(book_image.path)
      end

    rescue => e
      Rails.logger.error "Failed to generate combined image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      return nil
    end

    # Update submission with the image path
    submission.update!(generated_image_path: "/generated/#{filename}")
    
    "/generated/#{filename}"
  end
end
