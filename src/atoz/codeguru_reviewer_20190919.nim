
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CodeGuru Reviewer
## version: 2019-09-19
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This section provides documentation for the Amazon CodeGuru Reviewer API operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codeguru-reviewer/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "codeguru-reviewer.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codeguru-reviewer.ap-southeast-1.amazonaws.com", "us-west-2": "codeguru-reviewer.us-west-2.amazonaws.com", "eu-west-2": "codeguru-reviewer.eu-west-2.amazonaws.com", "ap-northeast-3": "codeguru-reviewer.ap-northeast-3.amazonaws.com", "eu-central-1": "codeguru-reviewer.eu-central-1.amazonaws.com", "us-east-2": "codeguru-reviewer.us-east-2.amazonaws.com", "us-east-1": "codeguru-reviewer.us-east-1.amazonaws.com", "cn-northwest-1": "codeguru-reviewer.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codeguru-reviewer.ap-south-1.amazonaws.com", "eu-north-1": "codeguru-reviewer.eu-north-1.amazonaws.com", "ap-northeast-2": "codeguru-reviewer.ap-northeast-2.amazonaws.com", "us-west-1": "codeguru-reviewer.us-west-1.amazonaws.com", "us-gov-east-1": "codeguru-reviewer.us-gov-east-1.amazonaws.com", "eu-west-3": "codeguru-reviewer.eu-west-3.amazonaws.com", "cn-north-1": "codeguru-reviewer.cn-north-1.amazonaws.com.cn", "sa-east-1": "codeguru-reviewer.sa-east-1.amazonaws.com", "eu-west-1": "codeguru-reviewer.eu-west-1.amazonaws.com", "us-gov-west-1": "codeguru-reviewer.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codeguru-reviewer.ap-southeast-2.amazonaws.com", "ca-central-1": "codeguru-reviewer.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "codeguru-reviewer.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codeguru-reviewer.ap-southeast-1.amazonaws.com",
      "us-west-2": "codeguru-reviewer.us-west-2.amazonaws.com",
      "eu-west-2": "codeguru-reviewer.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codeguru-reviewer.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codeguru-reviewer.eu-central-1.amazonaws.com",
      "us-east-2": "codeguru-reviewer.us-east-2.amazonaws.com",
      "us-east-1": "codeguru-reviewer.us-east-1.amazonaws.com",
      "cn-northwest-1": "codeguru-reviewer.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codeguru-reviewer.ap-south-1.amazonaws.com",
      "eu-north-1": "codeguru-reviewer.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codeguru-reviewer.ap-northeast-2.amazonaws.com",
      "us-west-1": "codeguru-reviewer.us-west-1.amazonaws.com",
      "us-gov-east-1": "codeguru-reviewer.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codeguru-reviewer.eu-west-3.amazonaws.com",
      "cn-north-1": "codeguru-reviewer.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codeguru-reviewer.sa-east-1.amazonaws.com",
      "eu-west-1": "codeguru-reviewer.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codeguru-reviewer.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codeguru-reviewer.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codeguru-reviewer.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codeguru-reviewer"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AssociateRepository_402656475 = ref object of OpenApiRestCall_402656038
proc url_AssociateRepository_402656477(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AssociateRepository_402656476(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
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
  var valid_402656478 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Security-Token", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Signature")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Signature", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Algorithm", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Date")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Date", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Credential")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Credential", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656484
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

proc call*(call_402656486: Call_AssociateRepository_402656475;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
                                                                                         ## 
  let valid = call_402656486.validator(path, query, header, formData, body, _)
  let scheme = call_402656486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656486.makeUrl(scheme.get, call_402656486.host, call_402656486.base,
                                   call_402656486.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656486, uri, valid, _)

proc call*(call_402656487: Call_AssociateRepository_402656475; body: JsonNode): Recallable =
  ## associateRepository
  ## <p>Associates an AWS CodeCommit repository with Amazon CodeGuru Reviewer. When you associate an AWS CodeCommit repository with Amazon CodeGuru Reviewer, Amazon CodeGuru Reviewer will provide recommendations for each pull request. You can view recommendations in the AWS CodeCommit repository.</p> <p>You can associate a GitHub repository using the Amazon CodeGuru Reviewer console.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656488 = newJObject()
  if body != nil:
    body_402656488 = body
  result = call_402656487.call(nil, nil, nil, nil, body_402656488)

var associateRepository* = Call_AssociateRepository_402656475(
    name: "associateRepository", meth: HttpMethod.HttpPost,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_AssociateRepository_402656476, base: "/",
    makeUrl: url_AssociateRepository_402656477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRepositoryAssociations_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListRepositoryAssociations_402656290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRepositoryAssociations_402656289(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProviderType: JArray
                                  ##               : List of provider types to use as a filter.
  ##   
                                                                                               ## Name: JArray
                                                                                               ##       
                                                                                               ## : 
                                                                                               ## List 
                                                                                               ## of 
                                                                                               ## names 
                                                                                               ## to 
                                                                                               ## use 
                                                                                               ## as 
                                                                                               ## a 
                                                                                               ## filter.
  ##   
                                                                                                         ## MaxResults: JInt
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## maximum 
                                                                                                         ## number 
                                                                                                         ## of 
                                                                                                         ## repository 
                                                                                                         ## association 
                                                                                                         ## results 
                                                                                                         ## returned 
                                                                                                         ## by 
                                                                                                         ## <code>ListRepositoryAssociations</code> 
                                                                                                         ## in 
                                                                                                         ## paginated 
                                                                                                         ## output. 
                                                                                                         ## When 
                                                                                                         ## this 
                                                                                                         ## parameter 
                                                                                                         ## is 
                                                                                                         ## used, 
                                                                                                         ## <code>ListRepositoryAssociations</code> 
                                                                                                         ## only 
                                                                                                         ## returns 
                                                                                                         ## <code>maxResults</code> 
                                                                                                         ## results 
                                                                                                         ## in 
                                                                                                         ## a 
                                                                                                         ## single 
                                                                                                         ## page 
                                                                                                         ## along 
                                                                                                         ## with 
                                                                                                         ## a 
                                                                                                         ## <code>nextToken</code> 
                                                                                                         ## response 
                                                                                                         ## element. 
                                                                                                         ## The 
                                                                                                         ## remaining 
                                                                                                         ## results 
                                                                                                         ## of 
                                                                                                         ## the 
                                                                                                         ## initial 
                                                                                                         ## request 
                                                                                                         ## can 
                                                                                                         ## be 
                                                                                                         ## seen 
                                                                                                         ## by 
                                                                                                         ## sending 
                                                                                                         ## another 
                                                                                                         ## <code>ListRepositoryAssociations</code> 
                                                                                                         ## request 
                                                                                                         ## with 
                                                                                                         ## the 
                                                                                                         ## returned 
                                                                                                         ## <code>nextToken</code> 
                                                                                                         ## value. 
                                                                                                         ## This 
                                                                                                         ## value 
                                                                                                         ## can 
                                                                                                         ## be 
                                                                                                         ## between 
                                                                                                         ## 1 
                                                                                                         ## and 
                                                                                                         ## 100. 
                                                                                                         ## If 
                                                                                                         ## this 
                                                                                                         ## parameter 
                                                                                                         ## is 
                                                                                                         ## not 
                                                                                                         ## used, 
                                                                                                         ## then 
                                                                                                         ## <code>ListRepositoryAssociations</code> 
                                                                                                         ## returns 
                                                                                                         ## up 
                                                                                                         ## to 
                                                                                                         ## 100 
                                                                                                         ## results 
                                                                                                         ## and 
                                                                                                         ## a 
                                                                                                         ## <code>nextToken</code> 
                                                                                                         ## value 
                                                                                                         ## if 
                                                                                                         ## applicable. 
  ##   
                                                                                                                        ## State: JArray
                                                                                                                        ##        
                                                                                                                        ## : 
                                                                                                                        ## List 
                                                                                                                        ## of 
                                                                                                                        ## states 
                                                                                                                        ## to 
                                                                                                                        ## use 
                                                                                                                        ## as 
                                                                                                                        ## a 
                                                                                                                        ## filter.
  ##   
                                                                                                                                  ## NextToken: JString
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## <p>The 
                                                                                                                                  ## <code>nextToken</code> 
                                                                                                                                  ## value 
                                                                                                                                  ## returned 
                                                                                                                                  ## from 
                                                                                                                                  ## a 
                                                                                                                                  ## previous 
                                                                                                                                  ## paginated 
                                                                                                                                  ## <code>ListRepositoryAssociations</code> 
                                                                                                                                  ## request 
                                                                                                                                  ## where 
                                                                                                                                  ## <code>maxResults</code> 
                                                                                                                                  ## was 
                                                                                                                                  ## used 
                                                                                                                                  ## and 
                                                                                                                                  ## the 
                                                                                                                                  ## results 
                                                                                                                                  ## exceeded 
                                                                                                                                  ## the 
                                                                                                                                  ## value 
                                                                                                                                  ## of 
                                                                                                                                  ## that 
                                                                                                                                  ## parameter. 
                                                                                                                                  ## Pagination 
                                                                                                                                  ## continues 
                                                                                                                                  ## from 
                                                                                                                                  ## the 
                                                                                                                                  ## end 
                                                                                                                                  ## of 
                                                                                                                                  ## the 
                                                                                                                                  ## previous 
                                                                                                                                  ## results 
                                                                                                                                  ## that 
                                                                                                                                  ## returned 
                                                                                                                                  ## the 
                                                                                                                                  ## <code>nextToken</code> 
                                                                                                                                  ## value. 
                                                                                                                                  ## </p> 
                                                                                                                                  ## <note> 
                                                                                                                                  ## <p>This 
                                                                                                                                  ## token 
                                                                                                                                  ## should 
                                                                                                                                  ## be 
                                                                                                                                  ## treated 
                                                                                                                                  ## as 
                                                                                                                                  ## an 
                                                                                                                                  ## opaque 
                                                                                                                                  ## identifier 
                                                                                                                                  ## that 
                                                                                                                                  ## is 
                                                                                                                                  ## only 
                                                                                                                                  ## used 
                                                                                                                                  ## to 
                                                                                                                                  ## retrieve 
                                                                                                                                  ## the 
                                                                                                                                  ## next 
                                                                                                                                  ## items 
                                                                                                                                  ## in 
                                                                                                                                  ## a 
                                                                                                                                  ## list 
                                                                                                                                  ## and 
                                                                                                                                  ## not 
                                                                                                                                  ## for 
                                                                                                                                  ## other 
                                                                                                                                  ## programmatic 
                                                                                                                                  ## purposes.</p> 
                                                                                                                                  ## </note>
  ##   
                                                                                                                                            ## Owner: JArray
                                                                                                                                            ##        
                                                                                                                                            ## : 
                                                                                                                                            ## List 
                                                                                                                                            ## of 
                                                                                                                                            ## owners 
                                                                                                                                            ## to 
                                                                                                                                            ## use 
                                                                                                                                            ## as 
                                                                                                                                            ## a 
                                                                                                                                            ## filter. 
                                                                                                                                            ## For 
                                                                                                                                            ## AWS 
                                                                                                                                            ## CodeCommit, 
                                                                                                                                            ## the 
                                                                                                                                            ## owner 
                                                                                                                                            ## is 
                                                                                                                                            ## the 
                                                                                                                                            ## AWS 
                                                                                                                                            ## account 
                                                                                                                                            ## id. 
                                                                                                                                            ## For 
                                                                                                                                            ## GitHub, 
                                                                                                                                            ## it 
                                                                                                                                            ## is 
                                                                                                                                            ## the 
                                                                                                                                            ## GitHub 
                                                                                                                                            ## account 
                                                                                                                                            ## name.
  section = newJObject()
  var valid_402656372 = query.getOrDefault("ProviderType")
  valid_402656372 = validateParameter(valid_402656372, JArray, required = false,
                                      default = nil)
  if valid_402656372 != nil:
    section.add "ProviderType", valid_402656372
  var valid_402656373 = query.getOrDefault("Name")
  valid_402656373 = validateParameter(valid_402656373, JArray, required = false,
                                      default = nil)
  if valid_402656373 != nil:
    section.add "Name", valid_402656373
  var valid_402656374 = query.getOrDefault("MaxResults")
  valid_402656374 = validateParameter(valid_402656374, JInt, required = false,
                                      default = nil)
  if valid_402656374 != nil:
    section.add "MaxResults", valid_402656374
  var valid_402656375 = query.getOrDefault("State")
  valid_402656375 = validateParameter(valid_402656375, JArray, required = false,
                                      default = nil)
  if valid_402656375 != nil:
    section.add "State", valid_402656375
  var valid_402656376 = query.getOrDefault("NextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "NextToken", valid_402656376
  var valid_402656377 = query.getOrDefault("Owner")
  valid_402656377 = validateParameter(valid_402656377, JArray, required = false,
                                      default = nil)
  if valid_402656377 != nil:
    section.add "Owner", valid_402656377
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
  var valid_402656378 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Security-Token", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Signature")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Signature", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Algorithm", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Date")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Date", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Credential")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Credential", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656398: Call_ListRepositoryAssociations_402656288;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
                                                                                         ## 
  let valid = call_402656398.validator(path, query, header, formData, body, _)
  let scheme = call_402656398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656398.makeUrl(scheme.get, call_402656398.host, call_402656398.base,
                                   call_402656398.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656398, uri, valid, _)

proc call*(call_402656447: Call_ListRepositoryAssociations_402656288;
           ProviderType: JsonNode = nil; Name: JsonNode = nil;
           MaxResults: int = 0; State: JsonNode = nil; NextToken: string = "";
           Owner: JsonNode = nil): Recallable =
  ## listRepositoryAssociations
  ## Lists repository associations. You can optionally filter on one or more of the following recommendation properties: provider types, states, names, and owners.
  ##   
                                                                                                                                                                   ## ProviderType: JArray
                                                                                                                                                                   ##               
                                                                                                                                                                   ## : 
                                                                                                                                                                   ## List 
                                                                                                                                                                   ## of 
                                                                                                                                                                   ## provider 
                                                                                                                                                                   ## types 
                                                                                                                                                                   ## to 
                                                                                                                                                                   ## use 
                                                                                                                                                                   ## as 
                                                                                                                                                                   ## a 
                                                                                                                                                                   ## filter.
  ##   
                                                                                                                                                                             ## Name: JArray
                                                                                                                                                                             ##       
                                                                                                                                                                             ## : 
                                                                                                                                                                             ## List 
                                                                                                                                                                             ## of 
                                                                                                                                                                             ## names 
                                                                                                                                                                             ## to 
                                                                                                                                                                             ## use 
                                                                                                                                                                             ## as 
                                                                                                                                                                             ## a 
                                                                                                                                                                             ## filter.
  ##   
                                                                                                                                                                                       ## MaxResults: int
                                                                                                                                                                                       ##             
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## The 
                                                                                                                                                                                       ## maximum 
                                                                                                                                                                                       ## number 
                                                                                                                                                                                       ## of 
                                                                                                                                                                                       ## repository 
                                                                                                                                                                                       ## association 
                                                                                                                                                                                       ## results 
                                                                                                                                                                                       ## returned 
                                                                                                                                                                                       ## by 
                                                                                                                                                                                       ## <code>ListRepositoryAssociations</code> 
                                                                                                                                                                                       ## in 
                                                                                                                                                                                       ## paginated 
                                                                                                                                                                                       ## output. 
                                                                                                                                                                                       ## When 
                                                                                                                                                                                       ## this 
                                                                                                                                                                                       ## parameter 
                                                                                                                                                                                       ## is 
                                                                                                                                                                                       ## used, 
                                                                                                                                                                                       ## <code>ListRepositoryAssociations</code> 
                                                                                                                                                                                       ## only 
                                                                                                                                                                                       ## returns 
                                                                                                                                                                                       ## <code>maxResults</code> 
                                                                                                                                                                                       ## results 
                                                                                                                                                                                       ## in 
                                                                                                                                                                                       ## a 
                                                                                                                                                                                       ## single 
                                                                                                                                                                                       ## page 
                                                                                                                                                                                       ## along 
                                                                                                                                                                                       ## with 
                                                                                                                                                                                       ## a 
                                                                                                                                                                                       ## <code>nextToken</code> 
                                                                                                                                                                                       ## response 
                                                                                                                                                                                       ## element. 
                                                                                                                                                                                       ## The 
                                                                                                                                                                                       ## remaining 
                                                                                                                                                                                       ## results 
                                                                                                                                                                                       ## of 
                                                                                                                                                                                       ## the 
                                                                                                                                                                                       ## initial 
                                                                                                                                                                                       ## request 
                                                                                                                                                                                       ## can 
                                                                                                                                                                                       ## be 
                                                                                                                                                                                       ## seen 
                                                                                                                                                                                       ## by 
                                                                                                                                                                                       ## sending 
                                                                                                                                                                                       ## another 
                                                                                                                                                                                       ## <code>ListRepositoryAssociations</code> 
                                                                                                                                                                                       ## request 
                                                                                                                                                                                       ## with 
                                                                                                                                                                                       ## the 
                                                                                                                                                                                       ## returned 
                                                                                                                                                                                       ## <code>nextToken</code> 
                                                                                                                                                                                       ## value. 
                                                                                                                                                                                       ## This 
                                                                                                                                                                                       ## value 
                                                                                                                                                                                       ## can 
                                                                                                                                                                                       ## be 
                                                                                                                                                                                       ## between 
                                                                                                                                                                                       ## 1 
                                                                                                                                                                                       ## and 
                                                                                                                                                                                       ## 100. 
                                                                                                                                                                                       ## If 
                                                                                                                                                                                       ## this 
                                                                                                                                                                                       ## parameter 
                                                                                                                                                                                       ## is 
                                                                                                                                                                                       ## not 
                                                                                                                                                                                       ## used, 
                                                                                                                                                                                       ## then 
                                                                                                                                                                                       ## <code>ListRepositoryAssociations</code> 
                                                                                                                                                                                       ## returns 
                                                                                                                                                                                       ## up 
                                                                                                                                                                                       ## to 
                                                                                                                                                                                       ## 100 
                                                                                                                                                                                       ## results 
                                                                                                                                                                                       ## and 
                                                                                                                                                                                       ## a 
                                                                                                                                                                                       ## <code>nextToken</code> 
                                                                                                                                                                                       ## value 
                                                                                                                                                                                       ## if 
                                                                                                                                                                                       ## applicable. 
  ##   
                                                                                                                                                                                                      ## State: JArray
                                                                                                                                                                                                      ##        
                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                      ## List 
                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                      ## states 
                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                      ## use 
                                                                                                                                                                                                      ## as 
                                                                                                                                                                                                      ## a 
                                                                                                                                                                                                      ## filter.
  ##   
                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                ## <p>The 
                                                                                                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                ## returned 
                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                ## previous 
                                                                                                                                                                                                                ## paginated 
                                                                                                                                                                                                                ## <code>ListRepositoryAssociations</code> 
                                                                                                                                                                                                                ## request 
                                                                                                                                                                                                                ## where 
                                                                                                                                                                                                                ## <code>maxResults</code> 
                                                                                                                                                                                                                ## was 
                                                                                                                                                                                                                ## used 
                                                                                                                                                                                                                ## and 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## results 
                                                                                                                                                                                                                ## exceeded 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## value 
                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                ## parameter. 
                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                ## continues 
                                                                                                                                                                                                                ## from 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## end 
                                                                                                                                                                                                                ## of 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## previous 
                                                                                                                                                                                                                ## results 
                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                ## returned 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                                                                                                ## value. 
                                                                                                                                                                                                                ## </p> 
                                                                                                                                                                                                                ## <note> 
                                                                                                                                                                                                                ## <p>This 
                                                                                                                                                                                                                ## token 
                                                                                                                                                                                                                ## should 
                                                                                                                                                                                                                ## be 
                                                                                                                                                                                                                ## treated 
                                                                                                                                                                                                                ## as 
                                                                                                                                                                                                                ## an 
                                                                                                                                                                                                                ## opaque 
                                                                                                                                                                                                                ## identifier 
                                                                                                                                                                                                                ## that 
                                                                                                                                                                                                                ## is 
                                                                                                                                                                                                                ## only 
                                                                                                                                                                                                                ## used 
                                                                                                                                                                                                                ## to 
                                                                                                                                                                                                                ## retrieve 
                                                                                                                                                                                                                ## the 
                                                                                                                                                                                                                ## next 
                                                                                                                                                                                                                ## items 
                                                                                                                                                                                                                ## in 
                                                                                                                                                                                                                ## a 
                                                                                                                                                                                                                ## list 
                                                                                                                                                                                                                ## and 
                                                                                                                                                                                                                ## not 
                                                                                                                                                                                                                ## for 
                                                                                                                                                                                                                ## other 
                                                                                                                                                                                                                ## programmatic 
                                                                                                                                                                                                                ## purposes.</p> 
                                                                                                                                                                                                                ## </note>
  ##   
                                                                                                                                                                                                                          ## Owner: JArray
                                                                                                                                                                                                                          ##        
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## List 
                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                          ## owners 
                                                                                                                                                                                                                          ## to 
                                                                                                                                                                                                                          ## use 
                                                                                                                                                                                                                          ## as 
                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                          ## filter. 
                                                                                                                                                                                                                          ## For 
                                                                                                                                                                                                                          ## AWS 
                                                                                                                                                                                                                          ## CodeCommit, 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## owner 
                                                                                                                                                                                                                          ## is 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## AWS 
                                                                                                                                                                                                                          ## account 
                                                                                                                                                                                                                          ## id. 
                                                                                                                                                                                                                          ## For 
                                                                                                                                                                                                                          ## GitHub, 
                                                                                                                                                                                                                          ## it 
                                                                                                                                                                                                                          ## is 
                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                          ## GitHub 
                                                                                                                                                                                                                          ## account 
                                                                                                                                                                                                                          ## name.
  var query_402656448 = newJObject()
  if ProviderType != nil:
    query_402656448.add "ProviderType", ProviderType
  if Name != nil:
    query_402656448.add "Name", Name
  add(query_402656448, "MaxResults", newJInt(MaxResults))
  if State != nil:
    query_402656448.add "State", State
  add(query_402656448, "NextToken", newJString(NextToken))
  if Owner != nil:
    query_402656448.add "Owner", Owner
  result = call_402656447.call(nil, query_402656448, nil, nil, nil)

var listRepositoryAssociations* = Call_ListRepositoryAssociations_402656288(
    name: "listRepositoryAssociations", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com", route: "/associations",
    validator: validate_ListRepositoryAssociations_402656289, base: "/",
    makeUrl: url_ListRepositoryAssociations_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRepositoryAssociation_402656489 = ref object of OpenApiRestCall_402656038
proc url_DescribeRepositoryAssociation_402656491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AssociationArn" in path,
         "`AssociationArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/associations/"),
                 (kind: VariableSegment, value: "AssociationArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeRepositoryAssociation_402656490(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes a repository association.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssociationArn: JString (required)
                                 ##                 : The Amazon Resource Name (ARN) identifying the association.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `AssociationArn` field"
  var valid_402656503 = path.getOrDefault("AssociationArn")
  valid_402656503 = validateParameter(valid_402656503, JString, required = true,
                                      default = nil)
  if valid_402656503 != nil:
    section.add "AssociationArn", valid_402656503
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
  var valid_402656504 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Security-Token", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Signature")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Signature", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Algorithm", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Date")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Date", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Credential")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Credential", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656511: Call_DescribeRepositoryAssociation_402656489;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a repository association.
                                                                                         ## 
  let valid = call_402656511.validator(path, query, header, formData, body, _)
  let scheme = call_402656511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656511.makeUrl(scheme.get, call_402656511.host, call_402656511.base,
                                   call_402656511.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656511, uri, valid, _)

proc call*(call_402656512: Call_DescribeRepositoryAssociation_402656489;
           AssociationArn: string): Recallable =
  ## describeRepositoryAssociation
  ## Describes a repository association.
  ##   AssociationArn: string (required)
                                        ##                 : The Amazon Resource Name (ARN) identifying the association.
  var path_402656513 = newJObject()
  add(path_402656513, "AssociationArn", newJString(AssociationArn))
  result = call_402656512.call(path_402656513, nil, nil, nil, nil)

var describeRepositoryAssociation* = Call_DescribeRepositoryAssociation_402656489(
    name: "describeRepositoryAssociation", meth: HttpMethod.HttpGet,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DescribeRepositoryAssociation_402656490, base: "/",
    makeUrl: url_DescribeRepositoryAssociation_402656491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DisassociateRepository_402656514 = ref object of OpenApiRestCall_402656038
proc url_DisassociateRepository_402656516(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AssociationArn" in path,
         "`AssociationArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/associations/"),
                 (kind: VariableSegment, value: "AssociationArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DisassociateRepository_402656515(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssociationArn: JString (required)
                                 ##                 : The Amazon Resource Name (ARN) identifying the association.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `AssociationArn` field"
  var valid_402656517 = path.getOrDefault("AssociationArn")
  valid_402656517 = validateParameter(valid_402656517, JString, required = true,
                                      default = nil)
  if valid_402656517 != nil:
    section.add "AssociationArn", valid_402656517
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
  var valid_402656518 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Security-Token", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Signature")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Signature", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Algorithm", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Date")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Date", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Credential")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Credential", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656525: Call_DisassociateRepository_402656514;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_DisassociateRepository_402656514;
           AssociationArn: string): Recallable =
  ## disassociateRepository
  ## Removes the association between Amazon CodeGuru Reviewer and a repository.
  ##   
                                                                               ## AssociationArn: string (required)
                                                                               ##                 
                                                                               ## : 
                                                                               ## The 
                                                                               ## Amazon 
                                                                               ## Resource 
                                                                               ## Name 
                                                                               ## (ARN) 
                                                                               ## identifying 
                                                                               ## the 
                                                                               ## association.
  var path_402656527 = newJObject()
  add(path_402656527, "AssociationArn", newJString(AssociationArn))
  result = call_402656526.call(path_402656527, nil, nil, nil, nil)

var disassociateRepository* = Call_DisassociateRepository_402656514(
    name: "disassociateRepository", meth: HttpMethod.HttpDelete,
    host: "codeguru-reviewer.amazonaws.com",
    route: "/associations/{AssociationArn}",
    validator: validate_DisassociateRepository_402656515, base: "/",
    makeUrl: url_DisassociateRepository_402656516,
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