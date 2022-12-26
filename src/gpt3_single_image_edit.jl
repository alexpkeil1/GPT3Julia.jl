"""
 Makes a single completion request to the GPT-3 API

 @description
 `gpt3_single_image_edit()` sends a single [image edit request](https://beta.openai.com/docs/api-reference/images/create-edit) to the Open AI GPT-3 API.
 @details For a general guide on the completion requests, see [https://beta.openai.com/docs/guides/images/introduction](https://beta.openai.com/docs/guides/images/introduction). This function provides you with an R wrapper to send requests with the full range of request parameters as detailed on [https://beta.openai.com/docs/api-reference/images/create-edit](https://beta.openai.com/docs/api-reference/images/create-edit) and reproduced below.


*Parameters*

   - `prompt_input`: character that contains the prompt to the GPT-3 request. (from the official API documentation: A text description of the desired image(s). The maximum length is 1000 characters.)
   - `n` numeric: (default: 1) specifying the number of completions per request (from the official API documentation: How many completions to generate for each prompt. **Note: Because this parameter generates many completions, it can quickly consume your token quota.** Use carefully and ensure that you have reasonable settings for max_tokens and stop._)
   - `size`: string (default: "256x256") one of "256x256", "512x512", "1024x1024" (from the official API documentation: The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024)
   - `image`: string (default: nothing) image url (MUST BE PNG) (from the official API documentation: The image to edit. Must be a valid PNG file, less than 4MB, and square. If mask is not provided, image must have transparency, which will be used as the mask.)
   - `mask`: string (default: nothing) image url (MUST BE PNG) (from the official API documentation: An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where image should be edited. Must be a valid PNG file, less than 4MB, and have the same dimensions as image.)
   - `response_format`: string  (default: "url")   one of "url", "b64_json" (from the official API documentation: The format in which the generated images are returned. Must be one of url or b64_json.)
   - `output_type`: character determining the output provided: "complete" (default), "image" or "meta"

 A tuple with two DataFrames (if `output_type` is the default "complete"): 
 
   - [1] contains the data table with the columns `n` (= the mo. of `n` responses requested), `prompt` (= the prompt that was sent), and `gpt3` (= the completion as returned from the GPT-3 model). 
   - [2] contains the meta information of the request, including the request id, the parameters of the request and the token usage of the prompt (`tok_usage_prompt`), the completion (`tok_usage_completion`) and the total usage (`tok_usage_total`).

 If `output_type` is "text", only the DataFrames in slot [1] is returned.

 If `output_type` is "meta", only the DataFrames in slot [2] is returned.


 _Examples_
 # First authenticate with your API key via `gpt3_authenticate("pathtokey")`
 # More here
 
"""
function gpt3_single_image_edit(
  p;
  prompt_input=p,
  n = 1,
  size = "256x256", # "512x512", "1024x1024"
  response_format = "url", # "b64_json"
  image = nothing,
  mask = nothing,
  output_type = "complete"
)
  check_api_exists()

  parameter_list = Dict(
    "prompt" => prompt_input,
    "n" => n,
    "size" => size,
    "image" => image,
    "mask" => mask,
    "response_format" => response_format
  )
    
  deletenothingkeys!(parameter_list)    
    
  headers = Dict(
    "Authorization" => "Bearer $api_key",
    "Content-Type" => "application/json"
    )

  request_base = HTTP.request(
    "POST",
    url.edits,
    body=JSON.json(parameter_list),
    headers=headers
  );
  # request_base.status
  if request_base.status == 200
    request_content = JSON.parse(String(request_base.body))
  end
  #
  if n == 1
    core_output = DataFrame(
                   "n" => 1,
                   "prompt" => prompt_input,
                   "gpt3" => request_content["data"][1]["url"]
                   )
  elseif n > 1
    core_output = DataFrame(
                   "n" => 1:n,
                   "prompt" => fill(prompt_input, n),
                   "gpt3" => fill("", n)
                   )
    for i in 1:n
      core_output.gpt3[i] = request_content["data"][i]["url"]
    end
  end

  meta_output = Dict(
    "request_created" => request_content["created"],
    "param_prompt" => prompt_input,
    "param_size" => size,
    "param_response_format" => response_format
  )

  if output_type == "complete"
    output = (core_output, meta_output)
  elseif output_type == "meta"
    output = meta_output
  elseif output_type == "image"
    output = core_output
  end
  return(output)
end

gpt3_single_image_edit(;prompt_input="",
n = 1,
size = "256x256", # "512x512", "1024x1024"
image = nothing,
mask = nothing,
response_format = "url", # "b64_json"
output_type = "complete"
) = gpt3_single_image_edit(
        prompt_input;
        prompt_input=prompt_input,
        n = n,
        size = size, 
        image = image,
        mask = mask,
        response_format = response_format,
        output_type = output_type
        )
;
