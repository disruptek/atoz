
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Polly
## version: 2016-06-10
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Polly is a web service that makes it easy to synthesize speech from text.</p> <p>The Amazon Polly service provides API operations for synthesizing high-quality speech from plain text and Speech Synthesis Markup Language (SSML), along with managing pronunciations lexicons that enable you to get the best results for your application domain.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/polly/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                       default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
                                                            ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "polly.ap-northeast-1.amazonaws.com", "ap-southeast-1": "polly.ap-southeast-1.amazonaws.com",
                               "us-west-2": "polly.us-west-2.amazonaws.com",
                               "eu-west-2": "polly.eu-west-2.amazonaws.com", "ap-northeast-3": "polly.ap-northeast-3.amazonaws.com", "eu-central-1": "polly.eu-central-1.amazonaws.com",
                               "us-east-2": "polly.us-east-2.amazonaws.com",
                               "us-east-1": "polly.us-east-1.amazonaws.com", "cn-northwest-1": "polly.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "polly.ap-south-1.amazonaws.com",
                               "eu-north-1": "polly.eu-north-1.amazonaws.com", "ap-northeast-2": "polly.ap-northeast-2.amazonaws.com",
                               "us-west-1": "polly.us-west-1.amazonaws.com", "us-gov-east-1": "polly.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "polly.eu-west-3.amazonaws.com", "cn-north-1": "polly.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "polly.sa-east-1.amazonaws.com",
                               "eu-west-1": "polly.eu-west-1.amazonaws.com", "us-gov-west-1": "polly.us-gov-west-1.amazonaws.com", "ap-southeast-2": "polly.ap-southeast-2.amazonaws.com", "ca-central-1": "polly.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "polly.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "polly.ap-southeast-1.amazonaws.com",
      "us-west-2": "polly.us-west-2.amazonaws.com",
      "eu-west-2": "polly.eu-west-2.amazonaws.com",
      "ap-northeast-3": "polly.ap-northeast-3.amazonaws.com",
      "eu-central-1": "polly.eu-central-1.amazonaws.com",
      "us-east-2": "polly.us-east-2.amazonaws.com",
      "us-east-1": "polly.us-east-1.amazonaws.com",
      "cn-northwest-1": "polly.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "polly.ap-south-1.amazonaws.com",
      "eu-north-1": "polly.eu-north-1.amazonaws.com",
      "ap-northeast-2": "polly.ap-northeast-2.amazonaws.com",
      "us-west-1": "polly.us-west-1.amazonaws.com",
      "us-gov-east-1": "polly.us-gov-east-1.amazonaws.com",
      "eu-west-3": "polly.eu-west-3.amazonaws.com",
      "cn-north-1": "polly.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "polly.sa-east-1.amazonaws.com",
      "eu-west-1": "polly.eu-west-1.amazonaws.com",
      "us-gov-west-1": "polly.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "polly.ap-southeast-2.amazonaws.com",
      "ca-central-1": "polly.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "polly"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_PutLexicon_402656481 = ref object of OpenApiRestCall_402656038
proc url_PutLexicon_402656483(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
                 (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutLexicon_402656482(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
                                 ##              : Name of the lexicon. The name must follow the regular express format [0-9A-Za-z]{1,20}. That is, the name is a case-sensitive alphanumeric string up to 20 characters long. 
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `LexiconName` field"
  var valid_402656484 = path.getOrDefault("LexiconName")
  valid_402656484 = validateParameter(valid_402656484, JString, required = true,
                                      default = nil)
  if valid_402656484 != nil:
    section.add "LexiconName", valid_402656484
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656485 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Security-Token", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Signature")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Signature", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Algorithm", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Date")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Date", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Credential")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Credential", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656493: Call_PutLexicon_402656481; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
                                                                                         ## 
  let valid = call_402656493.validator(path, query, header, formData, body, _)
  let scheme = call_402656493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656493.makeUrl(scheme.get, call_402656493.host, call_402656493.base,
                                   call_402656493.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656493, uri, valid, _)

proc call*(call_402656494: Call_PutLexicon_402656481; LexiconName: string;
           body: JsonNode): Recallable =
  ## putLexicon
  ## <p>Stores a pronunciation lexicon in an AWS Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## LexiconName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## lexicon. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## follow 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## regular 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## express 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## format 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## [0-9A-Za-z]{1,20}. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## That 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## is, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## case-sensitive 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## alphanumeric 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## string 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## 20 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## characters 
                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## long. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var path_402656495 = newJObject()
  var body_402656496 = newJObject()
  add(path_402656495, "LexiconName", newJString(LexiconName))
  if body != nil:
    body_402656496 = body
  result = call_402656494.call(path_402656495, nil, nil, nil, body_402656496)

var putLexicon* = Call_PutLexicon_402656481(name: "putLexicon",
    meth: HttpMethod.HttpPut, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_PutLexicon_402656482,
    base: "/", makeUrl: url_PutLexicon_402656483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLexicon_402656288 = ref object of OpenApiRestCall_402656038
proc url_GetLexicon_402656290(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
                 (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLexicon_402656289(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
                                 ##              : Name of the lexicon.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `LexiconName` field"
  var valid_402656380 = path.getOrDefault("LexiconName")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "LexiconName", valid_402656380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656381 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Security-Token", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Signature")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Signature", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Algorithm", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Date")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Date", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Credential")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Credential", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656401: Call_GetLexicon_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
                                                                                         ## 
  let valid = call_402656401.validator(path, query, header, formData, body, _)
  let scheme = call_402656401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656401.makeUrl(scheme.get, call_402656401.host, call_402656401.base,
                                   call_402656401.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656401, uri, valid, _)

proc call*(call_402656450: Call_GetLexicon_402656288; LexiconName: string): Recallable =
  ## getLexicon
  ## Returns the content of the specified pronunciation lexicon stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   
                                                                                                                                                                                                                      ## LexiconName: string (required)
                                                                                                                                                                                                                      ##              
                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                      ## Name 
                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                      ## lexicon.
  var path_402656451 = newJObject()
  add(path_402656451, "LexiconName", newJString(LexiconName))
  result = call_402656450.call(path_402656451, nil, nil, nil, nil)

var getLexicon* = Call_GetLexicon_402656288(name: "getLexicon",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_GetLexicon_402656289,
    base: "/", makeUrl: url_GetLexicon_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLexicon_402656497 = ref object of OpenApiRestCall_402656038
proc url_DeleteLexicon_402656499(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LexiconName" in path, "`LexiconName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/lexicons/"),
                 (kind: VariableSegment, value: "LexiconName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLexicon_402656498(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LexiconName: JString (required)
                                 ##              : The name of the lexicon to delete. Must be an existing lexicon in the region.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `LexiconName` field"
  var valid_402656500 = path.getOrDefault("LexiconName")
  valid_402656500 = validateParameter(valid_402656500, JString, required = true,
                                      default = nil)
  if valid_402656500 != nil:
    section.add "LexiconName", valid_402656500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656501 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Security-Token", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Signature")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Signature", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Algorithm", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Date")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Date", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Credential")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Credential", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656508: Call_DeleteLexicon_402656497; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
                                                                                         ## 
  let valid = call_402656508.validator(path, query, header, formData, body, _)
  let scheme = call_402656508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656508.makeUrl(scheme.get, call_402656508.host, call_402656508.base,
                                   call_402656508.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656508, uri, valid, _)

proc call*(call_402656509: Call_DeleteLexicon_402656497; LexiconName: string): Recallable =
  ## deleteLexicon
  ## <p>Deletes the specified pronunciation lexicon stored in an AWS Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the <code>GetLexicon</code> or <code>ListLexicon</code> APIs.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                          ## LexiconName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                          ##              
                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                          ## name 
                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                          ## lexicon 
                                                                                                                                                                                                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                                                                                                                                                                                                          ## delete. 
                                                                                                                                                                                                                                                                                                                                                                                                          ## Must 
                                                                                                                                                                                                                                                                                                                                                                                                          ## be 
                                                                                                                                                                                                                                                                                                                                                                                                          ## an 
                                                                                                                                                                                                                                                                                                                                                                                                          ## existing 
                                                                                                                                                                                                                                                                                                                                                                                                          ## lexicon 
                                                                                                                                                                                                                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                          ## region.
  var path_402656510 = newJObject()
  add(path_402656510, "LexiconName", newJString(LexiconName))
  result = call_402656509.call(path_402656510, nil, nil, nil, nil)

var deleteLexicon* = Call_DeleteLexicon_402656497(name: "deleteLexicon",
    meth: HttpMethod.HttpDelete, host: "polly.amazonaws.com",
    route: "/v1/lexicons/{LexiconName}", validator: validate_DeleteLexicon_402656498,
    base: "/", makeUrl: url_DeleteLexicon_402656499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeVoices_402656511 = ref object of OpenApiRestCall_402656038
proc url_DescribeVoices_402656513(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeVoices_402656512(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   LanguageCode: JString
                                  ##               :  The language identification tag (ISO 639 code for the language name-ISO 3166 country code) for filtering the list of voices returned. If you don't specify this optional parameter, all available voices are returned. 
  ##   
                                                                                                                                                                                                                                                                             ## NextToken: JString
                                                                                                                                                                                                                                                                             ##            
                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                             ## An 
                                                                                                                                                                                                                                                                             ## opaque 
                                                                                                                                                                                                                                                                             ## pagination 
                                                                                                                                                                                                                                                                             ## token 
                                                                                                                                                                                                                                                                             ## returned 
                                                                                                                                                                                                                                                                             ## from 
                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                             ## previous 
                                                                                                                                                                                                                                                                             ## <code>DescribeVoices</code> 
                                                                                                                                                                                                                                                                             ## operation. 
                                                                                                                                                                                                                                                                             ## If 
                                                                                                                                                                                                                                                                             ## present, 
                                                                                                                                                                                                                                                                             ## this 
                                                                                                                                                                                                                                                                             ## indicates 
                                                                                                                                                                                                                                                                             ## where 
                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                             ## continue 
                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                             ## listing.
  ##   
                                                                                                                                                                                                                                                                                        ## Engine: JString
                                                                                                                                                                                                                                                                                        ##         
                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                        ## Specifies 
                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                        ## engine 
                                                                                                                                                                                                                                                                                        ## (<code>standard</code> 
                                                                                                                                                                                                                                                                                        ## or 
                                                                                                                                                                                                                                                                                        ## <code>neural</code>) 
                                                                                                                                                                                                                                                                                        ## used 
                                                                                                                                                                                                                                                                                        ## by 
                                                                                                                                                                                                                                                                                        ## Amazon 
                                                                                                                                                                                                                                                                                        ## Polly 
                                                                                                                                                                                                                                                                                        ## when 
                                                                                                                                                                                                                                                                                        ## processing 
                                                                                                                                                                                                                                                                                        ## input 
                                                                                                                                                                                                                                                                                        ## text 
                                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                                        ## speech 
                                                                                                                                                                                                                                                                                        ## synthesis. 
  ##   
                                                                                                                                                                                                                                                                                                      ## IncludeAdditionalLanguageCodes: JBool
                                                                                                                                                                                                                                                                                                      ##                                 
                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                      ## Boolean 
                                                                                                                                                                                                                                                                                                      ## value 
                                                                                                                                                                                                                                                                                                      ## indicating 
                                                                                                                                                                                                                                                                                                      ## whether 
                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                      ## return 
                                                                                                                                                                                                                                                                                                      ## any 
                                                                                                                                                                                                                                                                                                      ## bilingual 
                                                                                                                                                                                                                                                                                                      ## voices 
                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                      ## specified 
                                                                                                                                                                                                                                                                                                      ## language 
                                                                                                                                                                                                                                                                                                      ## as 
                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                      ## additional 
                                                                                                                                                                                                                                                                                                      ## language. 
                                                                                                                                                                                                                                                                                                      ## For 
                                                                                                                                                                                                                                                                                                      ## instance, 
                                                                                                                                                                                                                                                                                                      ## if 
                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                      ## request 
                                                                                                                                                                                                                                                                                                      ## all 
                                                                                                                                                                                                                                                                                                      ## languages 
                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                                                                                                                      ## US 
                                                                                                                                                                                                                                                                                                      ## English 
                                                                                                                                                                                                                                                                                                      ## (es-US), 
                                                                                                                                                                                                                                                                                                      ## and 
                                                                                                                                                                                                                                                                                                      ## there 
                                                                                                                                                                                                                                                                                                      ## is 
                                                                                                                                                                                                                                                                                                      ## an 
                                                                                                                                                                                                                                                                                                      ## Italian 
                                                                                                                                                                                                                                                                                                      ## voice 
                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                      ## speaks 
                                                                                                                                                                                                                                                                                                      ## both 
                                                                                                                                                                                                                                                                                                      ## Italian 
                                                                                                                                                                                                                                                                                                      ## (it-IT) 
                                                                                                                                                                                                                                                                                                      ## and 
                                                                                                                                                                                                                                                                                                      ## US 
                                                                                                                                                                                                                                                                                                      ## English, 
                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                      ## voice 
                                                                                                                                                                                                                                                                                                      ## will 
                                                                                                                                                                                                                                                                                                      ## be 
                                                                                                                                                                                                                                                                                                      ## included 
                                                                                                                                                                                                                                                                                                      ## if 
                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                      ## specify 
                                                                                                                                                                                                                                                                                                      ## <code>yes</code> 
                                                                                                                                                                                                                                                                                                      ## but 
                                                                                                                                                                                                                                                                                                      ## not 
                                                                                                                                                                                                                                                                                                      ## if 
                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                      ## specify 
                                                                                                                                                                                                                                                                                                      ## <code>no</code>.
  section = newJObject()
  var valid_402656526 = query.getOrDefault("LanguageCode")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false,
                                      default = newJString("arb"))
  if valid_402656526 != nil:
    section.add "LanguageCode", valid_402656526
  var valid_402656527 = query.getOrDefault("NextToken")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "NextToken", valid_402656527
  var valid_402656528 = query.getOrDefault("Engine")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false,
                                      default = newJString("standard"))
  if valid_402656528 != nil:
    section.add "Engine", valid_402656528
  var valid_402656529 = query.getOrDefault("IncludeAdditionalLanguageCodes")
  valid_402656529 = validateParameter(valid_402656529, JBool, required = false,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "IncludeAdditionalLanguageCodes", valid_402656529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656530 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Security-Token", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Signature")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Signature", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Algorithm", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Date")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Date", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Credential")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Credential", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656537: Call_DescribeVoices_402656511; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
                                                                                         ## 
  let valid = call_402656537.validator(path, query, header, formData, body, _)
  let scheme = call_402656537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656537.makeUrl(scheme.get, call_402656537.host, call_402656537.base,
                                   call_402656537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656537, uri, valid, _)

proc call*(call_402656538: Call_DescribeVoices_402656511;
           LanguageCode: string = "arb"; NextToken: string = "";
           Engine: string = "standard";
           IncludeAdditionalLanguageCodes: bool = false): Recallable =
  ## describeVoices
  ## <p>Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. </p> <p>When synthesizing speech ( <code>SynthesizeSpeech</code> ), you provide the voice ID for the voice you want from the list of voices returned by <code>DescribeVoices</code>.</p> <p>For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the <code>DescribeVoices</code> operation you can provide the user with a list of available voices to select from.</p> <p> You can optionally specify a language code to filter the available voices. For example, if you specify <code>en-US</code>, the operation returns a list of all available US English voices. </p> <p>This operation requires permissions to perform the <code>polly:DescribeVoices</code> action.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## LanguageCode: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## :  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## language 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## identification 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## tag 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (ISO 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 639 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## code 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## language 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## name-ISO 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 3166 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## country 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## code) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## filtering 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## voices 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## returned. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## don't 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## optional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## parameter, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## available 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## voices 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## returned. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## An 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## opaque 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <code>DescribeVoices</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## operation. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## If 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## present, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## this 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## indicates 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## continue 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## listing.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Engine: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Specifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## engine 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## (<code>standard</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## <code>neural</code>) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## by 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Polly 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## when 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## processing 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## input 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## text 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## speech 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## synthesis. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## IncludeAdditionalLanguageCodes: bool
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ##                                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Boolean 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## indicating 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## whether 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## return 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## any 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## bilingual 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## voices 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## specified 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## language 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## additional 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## language. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## instance, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## all 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## languages 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## use 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## US 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## English 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## (es-US), 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## there 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Italian 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## voice 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## speaks 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## both 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## Italian 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## (it-IT) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## US 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## English, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## voice 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## will 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## included 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## <code>yes</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## but 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## if 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## <code>no</code>.
  var query_402656539 = newJObject()
  add(query_402656539, "LanguageCode", newJString(LanguageCode))
  add(query_402656539, "NextToken", newJString(NextToken))
  add(query_402656539, "Engine", newJString(Engine))
  add(query_402656539, "IncludeAdditionalLanguageCodes",
      newJBool(IncludeAdditionalLanguageCodes))
  result = call_402656538.call(nil, query_402656539, nil, nil, nil)

var describeVoices* = Call_DescribeVoices_402656511(name: "describeVoices",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com", route: "/v1/voices",
    validator: validate_DescribeVoices_402656512, base: "/",
    makeUrl: url_DescribeVoices_402656513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSpeechSynthesisTask_402656540 = ref object of OpenApiRestCall_402656038
proc url_GetSpeechSynthesisTask_402656542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "TaskId" in path, "`TaskId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/synthesisTasks/"),
                 (kind: VariableSegment, value: "TaskId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSpeechSynthesisTask_402656541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   TaskId: JString (required)
                                 ##         : The Amazon Polly generated identifier for a speech synthesis task.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `TaskId` field"
  var valid_402656543 = path.getOrDefault("TaskId")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true,
                                      default = nil)
  if valid_402656543 != nil:
    section.add "TaskId", valid_402656543
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656551: Call_GetSpeechSynthesisTask_402656540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_GetSpeechSynthesisTask_402656540; TaskId: string): Recallable =
  ## getSpeechSynthesisTask
  ## Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
  ##   
                                                                                                                                                                                                                                                  ## TaskId: string (required)
                                                                                                                                                                                                                                                  ##         
                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                                  ## Polly 
                                                                                                                                                                                                                                                  ## generated 
                                                                                                                                                                                                                                                  ## identifier 
                                                                                                                                                                                                                                                  ## for 
                                                                                                                                                                                                                                                  ## a 
                                                                                                                                                                                                                                                  ## speech 
                                                                                                                                                                                                                                                  ## synthesis 
                                                                                                                                                                                                                                                  ## task.
  var path_402656553 = newJObject()
  add(path_402656553, "TaskId", newJString(TaskId))
  result = call_402656552.call(path_402656553, nil, nil, nil, nil)

var getSpeechSynthesisTask* = Call_GetSpeechSynthesisTask_402656540(
    name: "getSpeechSynthesisTask", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks/{TaskId}",
    validator: validate_GetSpeechSynthesisTask_402656541, base: "/",
    makeUrl: url_GetSpeechSynthesisTask_402656542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLexicons_402656554 = ref object of OpenApiRestCall_402656038
proc url_ListLexicons_402656556(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLexicons_402656555(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : An opaque pagination token returned from previous <code>ListLexicons</code> operation. If present, indicates where to continue the list of lexicons.
  section = newJObject()
  var valid_402656557 = query.getOrDefault("NextToken")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "NextToken", valid_402656557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656558 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Security-Token", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Signature")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Signature", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Algorithm", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Date")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Date", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Credential")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Credential", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656565: Call_ListLexicons_402656554; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
                                                                                         ## 
  let valid = call_402656565.validator(path, query, header, formData, body, _)
  let scheme = call_402656565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656565.makeUrl(scheme.get, call_402656565.host, call_402656565.base,
                                   call_402656565.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656565, uri, valid, _)

proc call*(call_402656566: Call_ListLexicons_402656554; NextToken: string = ""): Recallable =
  ## listLexicons
  ## Returns a list of pronunciation lexicons stored in an AWS Region. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html">Managing Lexicons</a>.
  ##   
                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                    ##            
                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                    ## An 
                                                                                                                                                                                                    ## opaque 
                                                                                                                                                                                                    ## pagination 
                                                                                                                                                                                                    ## token 
                                                                                                                                                                                                    ## returned 
                                                                                                                                                                                                    ## from 
                                                                                                                                                                                                    ## previous 
                                                                                                                                                                                                    ## <code>ListLexicons</code> 
                                                                                                                                                                                                    ## operation. 
                                                                                                                                                                                                    ## If 
                                                                                                                                                                                                    ## present, 
                                                                                                                                                                                                    ## indicates 
                                                                                                                                                                                                    ## where 
                                                                                                                                                                                                    ## to 
                                                                                                                                                                                                    ## continue 
                                                                                                                                                                                                    ## the 
                                                                                                                                                                                                    ## list 
                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                    ## lexicons.
  var query_402656567 = newJObject()
  add(query_402656567, "NextToken", newJString(NextToken))
  result = call_402656566.call(nil, query_402656567, nil, nil, nil)

var listLexicons* = Call_ListLexicons_402656554(name: "listLexicons",
    meth: HttpMethod.HttpGet, host: "polly.amazonaws.com",
    route: "/v1/lexicons", validator: validate_ListLexicons_402656555,
    base: "/", makeUrl: url_ListLexicons_402656556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSpeechSynthesisTask_402656584 = ref object of OpenApiRestCall_402656038
proc url_StartSpeechSynthesisTask_402656586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSpeechSynthesisTask_402656585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656587 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Security-Token", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Signature")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Signature", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Algorithm", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Date")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Date", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Credential")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Credential", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656595: Call_StartSpeechSynthesisTask_402656584;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
                                                                                         ## 
  let valid = call_402656595.validator(path, query, header, formData, body, _)
  let scheme = call_402656595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656595.makeUrl(scheme.get, call_402656595.host, call_402656595.base,
                                   call_402656595.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656595, uri, valid, _)

proc call*(call_402656596: Call_StartSpeechSynthesisTask_402656584;
           body: JsonNode): Recallable =
  ## startSpeechSynthesisTask
  ## Allows the creation of an asynchronous synthesis task, by starting a new <code>SpeechSynthesisTask</code>. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402656597 = newJObject()
  if body != nil:
    body_402656597 = body
  result = call_402656596.call(nil, nil, nil, nil, body_402656597)

var startSpeechSynthesisTask* = Call_StartSpeechSynthesisTask_402656584(
    name: "startSpeechSynthesisTask", meth: HttpMethod.HttpPost,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_StartSpeechSynthesisTask_402656585, base: "/",
    makeUrl: url_StartSpeechSynthesisTask_402656586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSpeechSynthesisTasks_402656568 = ref object of OpenApiRestCall_402656038
proc url_ListSpeechSynthesisTasks_402656570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSpeechSynthesisTasks_402656569(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : Maximum number of speech synthesis tasks returned in a List operation.
  ##   
                                                                                                                         ## NextToken: JString
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## The 
                                                                                                                         ## pagination 
                                                                                                                         ## token 
                                                                                                                         ## to 
                                                                                                                         ## use 
                                                                                                                         ## in 
                                                                                                                         ## the 
                                                                                                                         ## next 
                                                                                                                         ## request 
                                                                                                                         ## to 
                                                                                                                         ## continue 
                                                                                                                         ## the 
                                                                                                                         ## listing 
                                                                                                                         ## of 
                                                                                                                         ## speech 
                                                                                                                         ## synthesis 
                                                                                                                         ## tasks. 
  ##   
                                                                                                                                   ## Status: JString
                                                                                                                                   ##         
                                                                                                                                   ## : 
                                                                                                                                   ## Status 
                                                                                                                                   ## of 
                                                                                                                                   ## the 
                                                                                                                                   ## speech 
                                                                                                                                   ## synthesis 
                                                                                                                                   ## tasks 
                                                                                                                                   ## returned 
                                                                                                                                   ## in 
                                                                                                                                   ## a 
                                                                                                                                   ## List 
                                                                                                                                   ## operation
  section = newJObject()
  var valid_402656571 = query.getOrDefault("MaxResults")
  valid_402656571 = validateParameter(valid_402656571, JInt, required = false,
                                      default = nil)
  if valid_402656571 != nil:
    section.add "MaxResults", valid_402656571
  var valid_402656572 = query.getOrDefault("NextToken")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "NextToken", valid_402656572
  var valid_402656573 = query.getOrDefault("Status")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false,
                                      default = newJString("scheduled"))
  if valid_402656573 != nil:
    section.add "Status", valid_402656573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Security-Token", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Signature")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Signature", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Algorithm", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Date")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Date", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Credential")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Credential", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656581: Call_ListSpeechSynthesisTasks_402656568;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
                                                                                         ## 
  let valid = call_402656581.validator(path, query, header, formData, body, _)
  let scheme = call_402656581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656581.makeUrl(scheme.get, call_402656581.host, call_402656581.base,
                                   call_402656581.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656581, uri, valid, _)

proc call*(call_402656582: Call_ListSpeechSynthesisTasks_402656568;
           MaxResults: int = 0; NextToken: string = "";
           Status: string = "scheduled"): Recallable =
  ## listSpeechSynthesisTasks
  ## Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
  ##   
                                                                                                                                                                                                          ## MaxResults: int
                                                                                                                                                                                                          ##             
                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                          ## Maximum 
                                                                                                                                                                                                          ## number 
                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                          ## speech 
                                                                                                                                                                                                          ## synthesis 
                                                                                                                                                                                                          ## tasks 
                                                                                                                                                                                                          ## returned 
                                                                                                                                                                                                          ## in 
                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                          ## List 
                                                                                                                                                                                                          ## operation.
  ##   
                                                                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                       ## pagination 
                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                       ## use 
                                                                                                                                                                                                                       ## in 
                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                       ## next 
                                                                                                                                                                                                                       ## request 
                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                       ## continue 
                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                       ## listing 
                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                       ## speech 
                                                                                                                                                                                                                       ## synthesis 
                                                                                                                                                                                                                       ## tasks. 
  ##   
                                                                                                                                                                                                                                 ## Status: string
                                                                                                                                                                                                                                 ##         
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Status 
                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                 ## speech 
                                                                                                                                                                                                                                 ## synthesis 
                                                                                                                                                                                                                                 ## tasks 
                                                                                                                                                                                                                                 ## returned 
                                                                                                                                                                                                                                 ## in 
                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                 ## List 
                                                                                                                                                                                                                                 ## operation
  var query_402656583 = newJObject()
  add(query_402656583, "MaxResults", newJInt(MaxResults))
  add(query_402656583, "NextToken", newJString(NextToken))
  add(query_402656583, "Status", newJString(Status))
  result = call_402656582.call(nil, query_402656583, nil, nil, nil)

var listSpeechSynthesisTasks* = Call_ListSpeechSynthesisTasks_402656568(
    name: "listSpeechSynthesisTasks", meth: HttpMethod.HttpGet,
    host: "polly.amazonaws.com", route: "/v1/synthesisTasks",
    validator: validate_ListSpeechSynthesisTasks_402656569, base: "/",
    makeUrl: url_ListSpeechSynthesisTasks_402656570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SynthesizeSpeech_402656598 = ref object of OpenApiRestCall_402656038
proc url_SynthesizeSpeech_402656600(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SynthesizeSpeech_402656599(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656601 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Security-Token", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Signature")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Signature", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Algorithm", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Date")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Date", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Credential")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Credential", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656609: Call_SynthesizeSpeech_402656598;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
                                                                                         ## 
  let valid = call_402656609.validator(path, query, header, formData, body, _)
  let scheme = call_402656609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656609.makeUrl(scheme.get, call_402656609.host, call_402656609.base,
                                   call_402656609.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656609, uri, valid, _)

proc call*(call_402656610: Call_SynthesizeSpeech_402656598; body: JsonNode): Recallable =
  ## synthesizeSpeech
  ## Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see <a href="https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html">How it Works</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  var body_402656611 = newJObject()
  if body != nil:
    body_402656611 = body
  result = call_402656610.call(nil, nil, nil, nil, body_402656611)

var synthesizeSpeech* = Call_SynthesizeSpeech_402656598(
    name: "synthesizeSpeech", meth: HttpMethod.HttpPost,
    host: "polly.amazonaws.com", route: "/v1/speech",
    validator: validate_SynthesizeSpeech_402656599, base: "/",
    makeUrl: url_SynthesizeSpeech_402656600,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}