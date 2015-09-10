classdef MEF_header < handle
    %% MEF_HEADER: Class for the header of the signal in MEF format 
    %%
    %%  currently support format MEF version up to 2.1
    %%
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    %% CC Jouny - Johns Hopkins University - 2014 (c) 
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (SetAccess = private)
        institution
        unencrypted_text_field
        encryption_algorithm
        subject_encryption_used
        session_encryption_used
        data_encryption_used
        byte_order_code
        header_version_major
        header_version_minor
        header_length
        session_unique_ID
        subject_first_name
        subject_second_name
        subject_third_name
        subject_id
        session_password
        subject_password_validation
        timestamp_adjustement_offset % added in 2.1
        %% Protected Region (unused)
        session_password_validation
        number_of_samples
        channel_name
        recording_start_time
        recording_end_time
        sampling_frequency
        low_frequency_filter_setting
        high_frequency_filter_setting
        notch_filter_frequency
        voltage_conversion_factor
        acquisition_system
        channel_comments
        study_comments
        physical_channel_number
        compression_algorithm
        maximum_compressed_block_size
        maximum_block_length
        block_interval
        maximum_data_value
        minimum_data_value
        index_data_offset
        number_of_index_entries
        block_header_length
        % Unused section
        
        %% Added after 2.1
        gmt_offset
        offset_discontinuity_indices
        number_discontinuity_index_entries
        % Unused section
        file_unique_identifier
        anonymized_subject_name
        header_CRC
    end
    
    properties (SetAccess = public)
        status=-1;                   % Default status -1=unset / 1=read/write success / 0=operation failed
    end
    
    properties (Dependent = true, SetAccess = private)
        %% String version of start and end time
        recording_start_date
        recording_end_date
    end
    
    methods
        
        function HDR=MEF_header()                                           % Constructor
        end
        
        function recording_start_date = get.recording_start_date(HDR)
            recording_start_date=usec2date(HDR.recording_start_time, 0);
        end
        
        function recording_end_date = get.recording_end_date(HDR)
            recording_end_date=usec2date(HDR.recording_end_time, 0);
        end
        
        function ReadFromFile(HDR, filename)
            if exist(filename, 'file')~=2,
                HDR.status=0;
                return;
            end
            % Open MEF file
            fp = fopen(filename, 'r');
            if fp == -1, 
                %disp('MEF_header:ReadFromFile', ['Could not open the file ' filename]);
                HDR.status=0;
                return;
            end
            fseek(fp, 0,-1);
            HDR.institution=deblank(fread(fp, 64, '*char')');
            HDR.unencrypted_text_field=deblank(fread(fp, 64, '*char')');
            HDR.encryption_algorithm=deblank(fread(fp, 32, '*char')');
            HDR.subject_encryption_used=fread(fp, 1, 'uint8');
            HDR.session_encryption_used=fread(fp, 1, 'uint8');
            HDR.data_encryption_used=fread(fp, 1, 'uint8');
            order=fread(fp, 1, 'uint8');
            if order, HDR.byte_order_code='little-endian'; else HDR.byte_order_code='big-endian'; end
            HDR.header_version_major=fread(fp, 1, 'uint8');
            HDR.header_version_minor=fread(fp, 1, 'uint8');       
            if HDR.header_version_major~=2,
                HDR.status=0;               % Cannot read major version != 2
                return;
            end         
            HDR.header_length=fread(fp, 1, 'uint16');
            HDR.session_unique_ID=fread(fp, 8, 'uint8');
            HDR.subject_first_name=deblank(fread(fp, 32, '*char')');
            HDR.subject_second_name=deblank(fread(fp, 32, '*char')');
            HDR.subject_third_name=deblank(fread(fp, 32, '*char')');
            HDR.subject_id=deblank(fread(fp, 32, '*char')');
            HDR.session_password=fread(fp, 16, '*char')';
            HDR.subject_password_validation=fread(fp, 16, '*char'); 
            if HDR.header_version_minor>=1,
                HDR.timestamp_adjustement_offset=double(fread(fp, 1, 'int64'));
            else
                HDR.timestamp_adjustement_offset=0;
                fread(fp, 1, 'int64');
            end
            fread(fp, 8, '*char');    % skip protected region
            HDR.session_password_validation=fread(fp, 16, '*char');
            HDR.number_of_samples=double(fread(fp, 1, 'uint64'));
            HDR.channel_name=deblank(fread(fp, 32, '*char')');
            HDR.recording_start_time=fread(fp, 1, 'uint64');
            HDR.recording_end_time=fread(fp, 1, 'uint64');
            HDR.sampling_frequency=fread(fp, 1, 'float64');
            HDR.low_frequency_filter_setting=fread(fp, 1, 'float64');
            HDR.high_frequency_filter_setting=fread(fp, 1, 'float64');
            HDR.notch_filter_frequency=fread(fp, 1, 'float64');
            HDR.voltage_conversion_factor=fread(fp, 1, 'float64');
            HDR.acquisition_system=deblank(fread(fp, 32, '*char')');
            HDR.channel_comments=deblank(fread(fp, 128, '*char')');
            HDR.study_comments=deblank(fread(fp, 128, '*char')');
            HDR.physical_channel_number=fread(fp,1,'int32');
            HDR.compression_algorithm=deblank(fread(fp, 32, '*char')');
            HDR.maximum_compressed_block_size=fread(fp,1,'uint32');
            HDR.maximum_block_length=fread(fp,1,'uint64');
            HDR.block_interval=fread(fp,1,'uint64');
            HDR.maximum_data_value=fread(fp,1,'int32');
            HDR.minimum_data_value=fread(fp,1,'int32');
            HDR.index_data_offset=fread(fp,1,'uint64');
            HDR.number_of_index_entries=fread(fp,1,'uint64');
            HDR.block_header_length=fread(fp,1,'uint16');
            
            if HDR.header_version_minor>=1,
                HDR.gmt_offset=fread(fp, 1, 'float32');
                HDR.offset_discontinuity_indices=fread(fp, 1, 'int64');
                HDR.number_discontinuity_index_entries=fread(fp, 1, 'int64');
                fread(fp, 92, '*char');  % skip unused region
                HDR.file_unique_identifier=fread(fp, 8, 'uint8');
                HDR.anonymized_subject_name=fread(fp, 64, '*char')';
                HDR.header_CRC=fread(fp, 1, 'uint32');
            end

            fclose(fp);         
            
            HDR.status=1;
        end   
        
    end % Methods
    
end % Class

