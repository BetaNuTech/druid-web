# frozen_string_literal: true

require 'rails_helper'

# Guards for two Active Storage advisories (see doc/security_advisories.md).
# Rails 7.2.3.2+ contains both fixes; these keep the app from drifting back
# into the conditions that made them exploitable:
#
#   CVE-2025-24293 / GHSA-r4mg-4433-c7g3 -- unsafe default transformation methods
#   CVE-2026-66066 / GHSA-xr9x-r78c-5hrm -- libvips "unfuzzed" loaders
RSpec.describe 'Active Storage hardening' do
  let(:image_path) { Rails.root.join('public', 'email_header_sapphire-620.png') }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(image_path),
      filename: 'logo.png',
      content_type: 'image/png'
    )
  end

  def dimensions(variant)
    image = MiniMagick::Image.read(variant.processed.download)
    [image.width, image.height]
  end

  describe 'the variants the views render' do
    # Every transformation used under app/views, so that a dependency change
    # that breaks image resizing fails here rather than in a broken <img>.
    it 'resizes to a fixed height (property logos in headers and quicklinks)' do
      expect(dimensions(blob.variant(resize: 'x30')).last).to eq(30)
    end

    it 'resizes to a fixed width (navbar profile photos)' do
      expect(dimensions(blob.variant(resize: '50x')).first).to eq(50)
      expect(dimensions(blob.variant(resize: '60x')).first).to eq(60)
    end

    it 'resizes to fit within a box (forms and property details)' do
      %w[100x100 150x150 200x200].each do |box|
        limit = box.split('x').first.to_i
        width, height = dimensions(blob.variant(resize: box))
        expect([width, height].max).to eq(limit)
      end
    end

    it 'treats the uploaded image types as variable' do
      expect(blob).to be_variable
    end
  end

  describe 'transformation arguments in the app' do
    # CVE-2025-24293 is only exploitable when request input reaches #variant.
    it 'are always literals, never request input' do
      calls = Dir[Rails.root.join('app', '**', '*.{rb,erb,haml,slim}')].flat_map do |file|
        File.readlines(file).grep(/\.(variant|preview|representation)\(/).map(&:strip)
      end
      calls.reject! { |line| line.include?('def self.variant') || line.include?('self.variant(data)') }

      expect(calls).not_to be_empty
      expect(calls).to all(match(/\.variant\(resize: ["'][0-9x]+["']\)/))
    end
  end

  describe 'CVE-2025-24293: unsafe transformation methods' do
    %w[apply loader saver].each do |method|
      it "does not allow ##{method}" do
        expect(ActiveStorage.supported_image_processing_methods).not_to include(method)
        expect { blob.variant(method => 'anything').processed }
          .to raise_error(ActiveStorage::Transformers::ImageProcessingTransformer::UnsupportedImageProcessingMethod)
      end
    end

    it 'still allows the methods the app uses' do
      expect(ActiveStorage.supported_image_processing_methods).to include('resize')
    end
  end

  describe 'CVE-2026-66066: libvips' do
    it 'processes variants with ImageMagick, not libvips' do
      expect(Rails.application.config.active_storage.variant_processor).to eq(:mini_magick)
      expect(ActiveStorage.variant_processor).to eq(:mini_magick)
    end

    # Active Storage 7.2 requires ruby-vips itself whenever the gem is
    # installed (active_storage/vips.rb), so "libvips is never loaded" no
    # longer holds. What matters is that it never processes an upload.
    it 'never hands a variant to libvips' do
      vips_usable = begin
        require 'image_processing/vips'
        true
      rescue LoadError
        false
      end

      expect(ImageProcessing::Vips).not_to receive(:source) if vips_usable
      expect(ImageProcessing::MiniMagick).to receive(:source).and_call_original

      blob.variant(resize: 'x30').processed
    end

    it 'runs a Rails release that contains the libvips fix' do
      expect(Gem::Version.new(ActiveStorage.version.to_s)).to be >= Gem::Version.new('7.2.3.2')
    end

    it 'blocks untrusted libvips operations should libvips ever be loaded' do
      expect(ENV.fetch('VIPS_BLOCK_UNTRUSTED', nil)).to be_present
    end
  end
end
