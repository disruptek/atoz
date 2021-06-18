
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elasticsearch Service
## version: 2015-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elasticsearch Configuration Service</fullname> <p>Use the Amazon Elasticsearch Configuration API to create, configure, and manage Elasticsearch domains.</p> <p>For sample code that uses the Configuration API, see the <a href="https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-configuration-samples.html">Amazon Elasticsearch Service Developer Guide</a>. The guide also contains <a href="https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-request-signing.html">sample code for sending signed HTTP requests to the Elasticsearch APIs</a>.</p> <p>The endpoint for configuration service requests is region-specific: es.<i>region</i>.amazonaws.com. For example, es.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticsearch-service-regions" target="_blank">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/es/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "es.ap-northeast-1.amazonaws.com", "ap-southeast-1": "es.ap-southeast-1.amazonaws.com",
                               "us-west-2": "es.us-west-2.amazonaws.com",
                               "eu-west-2": "es.eu-west-2.amazonaws.com", "ap-northeast-3": "es.ap-northeast-3.amazonaws.com",
                               "eu-central-1": "es.eu-central-1.amazonaws.com",
                               "us-east-2": "es.us-east-2.amazonaws.com",
                               "us-east-1": "es.us-east-1.amazonaws.com", "cn-northwest-1": "es.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "es.ap-south-1.amazonaws.com",
                               "eu-north-1": "es.eu-north-1.amazonaws.com", "ap-northeast-2": "es.ap-northeast-2.amazonaws.com",
                               "us-west-1": "es.us-west-1.amazonaws.com", "us-gov-east-1": "es.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "es.eu-west-3.amazonaws.com",
                               "cn-north-1": "es.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "es.sa-east-1.amazonaws.com",
                               "eu-west-1": "es.eu-west-1.amazonaws.com", "us-gov-west-1": "es.us-gov-west-1.amazonaws.com", "ap-southeast-2": "es.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "es.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "es.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "es.ap-southeast-1.amazonaws.com",
      "us-west-2": "es.us-west-2.amazonaws.com",
      "eu-west-2": "es.eu-west-2.amazonaws.com",
      "ap-northeast-3": "es.ap-northeast-3.amazonaws.com",
      "eu-central-1": "es.eu-central-1.amazonaws.com",
      "us-east-2": "es.us-east-2.amazonaws.com",
      "us-east-1": "es.us-east-1.amazonaws.com",
      "cn-northwest-1": "es.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "es.ap-south-1.amazonaws.com",
      "eu-north-1": "es.eu-north-1.amazonaws.com",
      "ap-northeast-2": "es.ap-northeast-2.amazonaws.com",
      "us-west-1": "es.us-west-1.amazonaws.com",
      "us-gov-east-1": "es.us-gov-east-1.amazonaws.com",
      "eu-west-3": "es.eu-west-3.amazonaws.com",
      "cn-north-1": "es.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "es.sa-east-1.amazonaws.com",
      "eu-west-1": "es.eu-west-1.amazonaws.com",
      "us-gov-west-1": "es.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "es.ap-southeast-2.amazonaws.com",
      "ca-central-1": "es.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "es"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddTags_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddTags_402656296(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_402656295(path: JsonNode; query: JsonNode;
                                header: JsonNode; formData: JsonNode;
                                body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656399: Call_AddTags_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
                                                                                         ## 
  let valid = call_402656399.validator(path, query, header, formData, body, _)
  let scheme = call_402656399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656399.makeUrl(scheme.get, call_402656399.host, call_402656399.base,
                                   call_402656399.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656399, uri, valid, _)

proc call*(call_402656448: Call_AddTags_402656294; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656449 = newJObject()
  if body != nil:
    body_402656449 = body
  result = call_402656448.call(nil, nil, nil, nil, body_402656449)

var addTags* = Call_AddTags_402656294(name: "addTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags",
                                      validator: validate_AddTags_402656295,
                                      base: "/", makeUrl: url_AddTags_402656296,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_402656476 = ref object of OpenApiRestCall_402656044
proc url_CancelElasticsearchServiceSoftwareUpdate_402656478(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_402656477(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
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
  var valid_402656479 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Security-Token", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-Signature")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Signature", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Algorithm", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Date")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Date", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Credential")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Credential", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656485
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

proc call*(call_402656487: Call_CancelElasticsearchServiceSoftwareUpdate_402656476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
                                                                                         ## 
  let valid = call_402656487.validator(path, query, header, formData, body, _)
  let scheme = call_402656487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656487.makeUrl(scheme.get, call_402656487.host, call_402656487.base,
                                   call_402656487.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656487, uri, valid, _)

proc call*(call_402656488: Call_CancelElasticsearchServiceSoftwareUpdate_402656476;
           body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   
                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656489 = newJObject()
  if body != nil:
    body_402656489 = body
  result = call_402656488.call(nil, nil, nil, nil, body_402656489)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_402656476(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_402656477,
    base: "/", makeUrl: url_CancelElasticsearchServiceSoftwareUpdate_402656478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_402656490 = ref object of OpenApiRestCall_402656044
proc url_CreateElasticsearchDomain_402656492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateElasticsearchDomain_402656491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
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
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
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

proc call*(call_402656501: Call_CreateElasticsearchDomain_402656490;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CreateElasticsearchDomain_402656490;
           body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_402656490(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_402656491, base: "/",
    makeUrl: url_CreateElasticsearchDomain_402656492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_402656504 = ref object of OpenApiRestCall_402656044
proc url_DescribeElasticsearchDomain_402656506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
                 (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomain_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656518 = path.getOrDefault("DomainName")
  valid_402656518 = validateParameter(valid_402656518, JString, required = true,
                                      default = nil)
  if valid_402656518 != nil:
    section.add "DomainName", valid_402656518
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
  var valid_402656519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Security-Token", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Signature")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Signature", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Algorithm", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Date")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Date", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Credential")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Credential", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656526: Call_DescribeElasticsearchDomain_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
                                                                                         ## 
  let valid = call_402656526.validator(path, query, header, formData, body, _)
  let scheme = call_402656526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656526.makeUrl(scheme.get, call_402656526.host, call_402656526.base,
                                   call_402656526.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656526, uri, valid, _)

proc call*(call_402656527: Call_DescribeElasticsearchDomain_402656504;
           DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   
                                                                                                                                                 ## DomainName: string (required)
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## an 
                                                                                                                                                 ## Elasticsearch 
                                                                                                                                                 ## domain. 
                                                                                                                                                 ## Domain 
                                                                                                                                                 ## names 
                                                                                                                                                 ## are 
                                                                                                                                                 ## unique 
                                                                                                                                                 ## across 
                                                                                                                                                 ## the 
                                                                                                                                                 ## domains 
                                                                                                                                                 ## owned 
                                                                                                                                                 ## by 
                                                                                                                                                 ## an 
                                                                                                                                                 ## account 
                                                                                                                                                 ## within 
                                                                                                                                                 ## an 
                                                                                                                                                 ## AWS 
                                                                                                                                                 ## region. 
                                                                                                                                                 ## Domain 
                                                                                                                                                 ## names 
                                                                                                                                                 ## start 
                                                                                                                                                 ## with 
                                                                                                                                                 ## a 
                                                                                                                                                 ## letter 
                                                                                                                                                 ## or 
                                                                                                                                                 ## number 
                                                                                                                                                 ## and 
                                                                                                                                                 ## can 
                                                                                                                                                 ## contain 
                                                                                                                                                 ## the 
                                                                                                                                                 ## following 
                                                                                                                                                 ## characters: 
                                                                                                                                                 ## a-z 
                                                                                                                                                 ## (lowercase), 
                                                                                                                                                 ## 0-9, 
                                                                                                                                                 ## and 
                                                                                                                                                 ## - 
                                                                                                                                                 ## (hyphen).
  var path_402656528 = newJObject()
  add(path_402656528, "DomainName", newJString(DomainName))
  result = call_402656527.call(path_402656528, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_402656504(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_402656505, base: "/",
    makeUrl: url_DescribeElasticsearchDomain_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_402656529 = ref object of OpenApiRestCall_402656044
proc url_DeleteElasticsearchDomain_402656531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
                 (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteElasticsearchDomain_402656530(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656532 = path.getOrDefault("DomainName")
  valid_402656532 = validateParameter(valid_402656532, JString, required = true,
                                      default = nil)
  if valid_402656532 != nil:
    section.add "DomainName", valid_402656532
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
  var valid_402656533 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Security-Token", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Signature")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Signature", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Algorithm", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Date")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Date", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Credential")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Credential", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656540: Call_DeleteElasticsearchDomain_402656529;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_DeleteElasticsearchDomain_402656529;
           DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   
                                                                                                                                  ## DomainName: string (required)
                                                                                                                                  ##             
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## name 
                                                                                                                                  ## of 
                                                                                                                                  ## an 
                                                                                                                                  ## Elasticsearch 
                                                                                                                                  ## domain. 
                                                                                                                                  ## Domain 
                                                                                                                                  ## names 
                                                                                                                                  ## are 
                                                                                                                                  ## unique 
                                                                                                                                  ## across 
                                                                                                                                  ## the 
                                                                                                                                  ## domains 
                                                                                                                                  ## owned 
                                                                                                                                  ## by 
                                                                                                                                  ## an 
                                                                                                                                  ## account 
                                                                                                                                  ## within 
                                                                                                                                  ## an 
                                                                                                                                  ## AWS 
                                                                                                                                  ## region. 
                                                                                                                                  ## Domain 
                                                                                                                                  ## names 
                                                                                                                                  ## start 
                                                                                                                                  ## with 
                                                                                                                                  ## a 
                                                                                                                                  ## letter 
                                                                                                                                  ## or 
                                                                                                                                  ## number 
                                                                                                                                  ## and 
                                                                                                                                  ## can 
                                                                                                                                  ## contain 
                                                                                                                                  ## the 
                                                                                                                                  ## following 
                                                                                                                                  ## characters: 
                                                                                                                                  ## a-z 
                                                                                                                                  ## (lowercase), 
                                                                                                                                  ## 0-9, 
                                                                                                                                  ## and 
                                                                                                                                  ## - 
                                                                                                                                  ## (hyphen).
  var path_402656542 = newJObject()
  add(path_402656542, "DomainName", newJString(DomainName))
  result = call_402656541.call(path_402656542, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_402656529(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_402656530, base: "/",
    makeUrl: url_DeleteElasticsearchDomain_402656531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_402656543 = ref object of OpenApiRestCall_402656044
proc url_DeleteElasticsearchServiceRole_402656545(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteElasticsearchServiceRole_402656544(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
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
  var valid_402656546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Security-Token", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Signature")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Signature", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Algorithm", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Date")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Date", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Credential")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Credential", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656552
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656553: Call_DeleteElasticsearchServiceRole_402656543;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
                                                                                         ## 
  let valid = call_402656553.validator(path, query, header, formData, body, _)
  let scheme = call_402656553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656553.makeUrl(scheme.get, call_402656553.host, call_402656553.base,
                                   call_402656553.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656553, uri, valid, _)

proc call*(call_402656554: Call_DeleteElasticsearchServiceRole_402656543): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_402656554.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_402656543(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_402656544, base: "/",
    makeUrl: url_DeleteElasticsearchServiceRole_402656545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_402656569 = ref object of OpenApiRestCall_402656044
proc url_UpdateElasticsearchDomainConfig_402656571(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
                 (kind: VariableSegment, value: "DomainName"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateElasticsearchDomainConfig_402656570(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656572 = path.getOrDefault("DomainName")
  valid_402656572 = validateParameter(valid_402656572, JString, required = true,
                                      default = nil)
  if valid_402656572 != nil:
    section.add "DomainName", valid_402656572
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
  var valid_402656573 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Security-Token", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Signature")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Signature", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Algorithm", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Date")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Date", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Credential")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Credential", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656579
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

proc call*(call_402656581: Call_UpdateElasticsearchDomainConfig_402656569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
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

proc call*(call_402656582: Call_UpdateElasticsearchDomainConfig_402656569;
           DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   
                                                                                                                                                 ## DomainName: string (required)
                                                                                                                                                 ##             
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## an 
                                                                                                                                                 ## Elasticsearch 
                                                                                                                                                 ## domain. 
                                                                                                                                                 ## Domain 
                                                                                                                                                 ## names 
                                                                                                                                                 ## are 
                                                                                                                                                 ## unique 
                                                                                                                                                 ## across 
                                                                                                                                                 ## the 
                                                                                                                                                 ## domains 
                                                                                                                                                 ## owned 
                                                                                                                                                 ## by 
                                                                                                                                                 ## an 
                                                                                                                                                 ## account 
                                                                                                                                                 ## within 
                                                                                                                                                 ## an 
                                                                                                                                                 ## AWS 
                                                                                                                                                 ## region. 
                                                                                                                                                 ## Domain 
                                                                                                                                                 ## names 
                                                                                                                                                 ## start 
                                                                                                                                                 ## with 
                                                                                                                                                 ## a 
                                                                                                                                                 ## letter 
                                                                                                                                                 ## or 
                                                                                                                                                 ## number 
                                                                                                                                                 ## and 
                                                                                                                                                 ## can 
                                                                                                                                                 ## contain 
                                                                                                                                                 ## the 
                                                                                                                                                 ## following 
                                                                                                                                                 ## characters: 
                                                                                                                                                 ## a-z 
                                                                                                                                                 ## (lowercase), 
                                                                                                                                                 ## 0-9, 
                                                                                                                                                 ## and 
                                                                                                                                                 ## - 
                                                                                                                                                 ## (hyphen).
  ##   
                                                                                                                                                             ## body: JObject (required)
  var path_402656583 = newJObject()
  var body_402656584 = newJObject()
  add(path_402656583, "DomainName", newJString(DomainName))
  if body != nil:
    body_402656584 = body
  result = call_402656582.call(path_402656583, nil, nil, nil, body_402656584)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_402656569(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_402656570, base: "/",
    makeUrl: url_UpdateElasticsearchDomainConfig_402656571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_402656555 = ref object of OpenApiRestCall_402656044
proc url_DescribeElasticsearchDomainConfig_402656557(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
                 (kind: VariableSegment, value: "DomainName"),
                 (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomainConfig_402656556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656558 = path.getOrDefault("DomainName")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true,
                                      default = nil)
  if valid_402656558 != nil:
    section.add "DomainName", valid_402656558
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
  var valid_402656559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Security-Token", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Signature")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Signature", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Algorithm", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Date")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Date", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Credential")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Credential", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656566: Call_DescribeElasticsearchDomainConfig_402656555;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
                                                                                         ## 
  let valid = call_402656566.validator(path, query, header, formData, body, _)
  let scheme = call_402656566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656566.makeUrl(scheme.get, call_402656566.host, call_402656566.base,
                                   call_402656566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656566, uri, valid, _)

proc call*(call_402656567: Call_DescribeElasticsearchDomainConfig_402656555;
           DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   
                                                                                                                                                                                ## DomainName: string (required)
                                                                                                                                                                                ##             
                                                                                                                                                                                ## : 
                                                                                                                                                                                ## The 
                                                                                                                                                                                ## name 
                                                                                                                                                                                ## of 
                                                                                                                                                                                ## an 
                                                                                                                                                                                ## Elasticsearch 
                                                                                                                                                                                ## domain. 
                                                                                                                                                                                ## Domain 
                                                                                                                                                                                ## names 
                                                                                                                                                                                ## are 
                                                                                                                                                                                ## unique 
                                                                                                                                                                                ## across 
                                                                                                                                                                                ## the 
                                                                                                                                                                                ## domains 
                                                                                                                                                                                ## owned 
                                                                                                                                                                                ## by 
                                                                                                                                                                                ## an 
                                                                                                                                                                                ## account 
                                                                                                                                                                                ## within 
                                                                                                                                                                                ## an 
                                                                                                                                                                                ## AWS 
                                                                                                                                                                                ## region. 
                                                                                                                                                                                ## Domain 
                                                                                                                                                                                ## names 
                                                                                                                                                                                ## start 
                                                                                                                                                                                ## with 
                                                                                                                                                                                ## a 
                                                                                                                                                                                ## letter 
                                                                                                                                                                                ## or 
                                                                                                                                                                                ## number 
                                                                                                                                                                                ## and 
                                                                                                                                                                                ## can 
                                                                                                                                                                                ## contain 
                                                                                                                                                                                ## the 
                                                                                                                                                                                ## following 
                                                                                                                                                                                ## characters: 
                                                                                                                                                                                ## a-z 
                                                                                                                                                                                ## (lowercase), 
                                                                                                                                                                                ## 0-9, 
                                                                                                                                                                                ## and 
                                                                                                                                                                                ## - 
                                                                                                                                                                                ## (hyphen).
  var path_402656568 = newJObject()
  add(path_402656568, "DomainName", newJString(DomainName))
  result = call_402656567.call(path_402656568, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_402656555(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_402656556, base: "/",
    makeUrl: url_DescribeElasticsearchDomainConfig_402656557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_402656585 = ref object of OpenApiRestCall_402656044
proc url_DescribeElasticsearchDomains_402656587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeElasticsearchDomains_402656586(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
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
  var valid_402656588 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Security-Token", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Signature")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Signature", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Algorithm", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-Date")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-Date", valid_402656592
  var valid_402656593 = header.getOrDefault("X-Amz-Credential")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Credential", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656594
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

proc call*(call_402656596: Call_DescribeElasticsearchDomains_402656585;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
                                                                                         ## 
  let valid = call_402656596.validator(path, query, header, formData, body, _)
  let scheme = call_402656596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656596.makeUrl(scheme.get, call_402656596.host, call_402656596.base,
                                   call_402656596.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656596, uri, valid, _)

proc call*(call_402656597: Call_DescribeElasticsearchDomains_402656585;
           body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   
                                                                                                                                                  ## body: JObject (required)
  var body_402656598 = newJObject()
  if body != nil:
    body_402656598 = body
  result = call_402656597.call(nil, nil, nil, nil, body_402656598)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_402656585(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_402656586, base: "/",
    makeUrl: url_DescribeElasticsearchDomains_402656587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_402656599 = ref object of OpenApiRestCall_402656044
proc url_DescribeElasticsearchInstanceTypeLimits_402656601(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
         "`ElasticsearchVersion` is a required path parameter"
  assert "InstanceType" in path, "`InstanceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                  value: "/2015-01-01/es/instanceTypeLimits/"),
                 (kind: VariableSegment, value: "ElasticsearchVersion"),
                 (kind: ConstantSegment, value: "/"),
                 (kind: VariableSegment, value: "InstanceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchInstanceTypeLimits_402656600(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ElasticsearchVersion: JString (required)
                                 ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  ##   
                                                                                                                                         ## InstanceType: JString (required)
                                                                                                                                         ##               
                                                                                                                                         ## :  
                                                                                                                                         ## The 
                                                                                                                                         ## instance 
                                                                                                                                         ## type 
                                                                                                                                         ## for 
                                                                                                                                         ## an 
                                                                                                                                         ## Elasticsearch 
                                                                                                                                         ## cluster 
                                                                                                                                         ## for 
                                                                                                                                         ## which 
                                                                                                                                         ## Elasticsearch 
                                                                                                                                         ## <code> 
                                                                                                                                         ## <a>Limits</a> 
                                                                                                                                         ## </code> 
                                                                                                                                         ## are 
                                                                                                                                         ## needed. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ElasticsearchVersion` field"
  var valid_402656602 = path.getOrDefault("ElasticsearchVersion")
  valid_402656602 = validateParameter(valid_402656602, JString, required = true,
                                      default = nil)
  if valid_402656602 != nil:
    section.add "ElasticsearchVersion", valid_402656602
  var valid_402656615 = path.getOrDefault("InstanceType")
  valid_402656615 = validateParameter(valid_402656615, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_402656615 != nil:
    section.add "InstanceType", valid_402656615
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
                                  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_402656616 = query.getOrDefault("domainName")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "domainName", valid_402656616
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
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656624: Call_DescribeElasticsearchInstanceTypeLimits_402656599;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
                                                                                         ## 
  let valid = call_402656624.validator(path, query, header, formData, body, _)
  let scheme = call_402656624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656624.makeUrl(scheme.get, call_402656624.host, call_402656624.base,
                                   call_402656624.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656624, uri, valid, _)

proc call*(call_402656625: Call_DescribeElasticsearchInstanceTypeLimits_402656599;
           ElasticsearchVersion: string; domainName: string = "";
           InstanceType: string = "m3.medium.elasticsearch"): Recallable =
  ## describeElasticsearchInstanceTypeLimits
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ##   
                                                                                                                                                                                                                     ## domainName: string
                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                     ## Elasticsearch 
                                                                                                                                                                                                                     ## domain. 
                                                                                                                                                                                                                     ## Domain 
                                                                                                                                                                                                                     ## names 
                                                                                                                                                                                                                     ## are 
                                                                                                                                                                                                                     ## unique 
                                                                                                                                                                                                                     ## across 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## domains 
                                                                                                                                                                                                                     ## owned 
                                                                                                                                                                                                                     ## by 
                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                     ## account 
                                                                                                                                                                                                                     ## within 
                                                                                                                                                                                                                     ## an 
                                                                                                                                                                                                                     ## AWS 
                                                                                                                                                                                                                     ## region. 
                                                                                                                                                                                                                     ## Domain 
                                                                                                                                                                                                                     ## names 
                                                                                                                                                                                                                     ## start 
                                                                                                                                                                                                                     ## with 
                                                                                                                                                                                                                     ## a 
                                                                                                                                                                                                                     ## letter 
                                                                                                                                                                                                                     ## or 
                                                                                                                                                                                                                     ## number 
                                                                                                                                                                                                                     ## and 
                                                                                                                                                                                                                     ## can 
                                                                                                                                                                                                                     ## contain 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## following 
                                                                                                                                                                                                                     ## characters: 
                                                                                                                                                                                                                     ## a-z 
                                                                                                                                                                                                                     ## (lowercase), 
                                                                                                                                                                                                                     ## 0-9, 
                                                                                                                                                                                                                     ## and 
                                                                                                                                                                                                                     ## - 
                                                                                                                                                                                                                     ## (hyphen).
  ##   
                                                                                                                                                                                                                                 ## ElasticsearchVersion: string (required)
                                                                                                                                                                                                                                 ##                       
                                                                                                                                                                                                                                 ## :  
                                                                                                                                                                                                                                 ## Version 
                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                 ## Elasticsearch 
                                                                                                                                                                                                                                 ## for 
                                                                                                                                                                                                                                 ## which 
                                                                                                                                                                                                                                 ## <code> 
                                                                                                                                                                                                                                 ## <a>Limits</a> 
                                                                                                                                                                                                                                 ## </code> 
                                                                                                                                                                                                                                 ## are 
                                                                                                                                                                                                                                 ## needed. 
  ##   
                                                                                                                                                                                                                                            ## InstanceType: string (required)
                                                                                                                                                                                                                                            ##               
                                                                                                                                                                                                                                            ## :  
                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                            ## instance 
                                                                                                                                                                                                                                            ## type 
                                                                                                                                                                                                                                            ## for 
                                                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                                                            ## Elasticsearch 
                                                                                                                                                                                                                                            ## cluster 
                                                                                                                                                                                                                                            ## for 
                                                                                                                                                                                                                                            ## which 
                                                                                                                                                                                                                                            ## Elasticsearch 
                                                                                                                                                                                                                                            ## <code> 
                                                                                                                                                                                                                                            ## <a>Limits</a> 
                                                                                                                                                                                                                                            ## </code> 
                                                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                                                            ## needed. 
  var path_402656626 = newJObject()
  var query_402656627 = newJObject()
  add(query_402656627, "domainName", newJString(domainName))
  add(path_402656626, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(path_402656626, "InstanceType", newJString(InstanceType))
  result = call_402656625.call(path_402656626, query_402656627, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_402656599(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_402656600,
    base: "/", makeUrl: url_DescribeElasticsearchInstanceTypeLimits_402656601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_402656628 = ref object of OpenApiRestCall_402656044
proc url_DescribeReservedElasticsearchInstanceOfferings_402656630(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_402656629(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Lists available reserved Elasticsearch instance offerings.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   offeringId: JString
                                  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   
                                                                                                                                                                                                  ## maxResults: JInt
                                                                                                                                                                                                  ##             
                                                                                                                                                                                                  ## :  
                                                                                                                                                                                                  ## Set 
                                                                                                                                                                                                  ## this 
                                                                                                                                                                                                  ## value 
                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                  ## limit 
                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                  ## number 
                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                  ## results 
                                                                                                                                                                                                  ## returned. 
  ##   
                                                                                                                                                                                                               ## nextToken: JString
                                                                                                                                                                                                               ##            
                                                                                                                                                                                                               ## :  
                                                                                                                                                                                                               ## Paginated 
                                                                                                                                                                                                               ## APIs 
                                                                                                                                                                                                               ## accepts 
                                                                                                                                                                                                               ## NextToken 
                                                                                                                                                                                                               ## input 
                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                               ## returns 
                                                                                                                                                                                                               ## next 
                                                                                                                                                                                                               ## page 
                                                                                                                                                                                                               ## results 
                                                                                                                                                                                                               ## and 
                                                                                                                                                                                                               ## provides 
                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                               ## NextToken 
                                                                                                                                                                                                               ## output 
                                                                                                                                                                                                               ## in 
                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                               ## response 
                                                                                                                                                                                                               ## which 
                                                                                                                                                                                                               ## can 
                                                                                                                                                                                                               ## be 
                                                                                                                                                                                                               ## used 
                                                                                                                                                                                                               ## by 
                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                               ## client 
                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                               ## retrieve 
                                                                                                                                                                                                               ## more 
                                                                                                                                                                                                               ## results. 
  ##   
                                                                                                                                                                                                                           ## MaxResults: JString
                                                                                                                                                                                                                           ##             
                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                           ## limit
  ##   
                                                                                                                                                                                                                                   ## NextToken: JString
                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                   ## token
  section = newJObject()
  var valid_402656631 = query.getOrDefault("offeringId")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "offeringId", valid_402656631
  var valid_402656632 = query.getOrDefault("maxResults")
  valid_402656632 = validateParameter(valid_402656632, JInt, required = false,
                                      default = nil)
  if valid_402656632 != nil:
    section.add "maxResults", valid_402656632
  var valid_402656633 = query.getOrDefault("nextToken")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "nextToken", valid_402656633
  var valid_402656634 = query.getOrDefault("MaxResults")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "MaxResults", valid_402656634
  var valid_402656635 = query.getOrDefault("NextToken")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "NextToken", valid_402656635
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
  var valid_402656636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Security-Token", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-Signature")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Signature", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Algorithm", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Date")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Date", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Credential")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Credential", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656643: Call_DescribeReservedElasticsearchInstanceOfferings_402656628;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
                                                                                         ## 
  let valid = call_402656643.validator(path, query, header, formData, body, _)
  let scheme = call_402656643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656643.makeUrl(scheme.get, call_402656643.host, call_402656643.base,
                                   call_402656643.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656643, uri, valid, _)

proc call*(call_402656644: Call_DescribeReservedElasticsearchInstanceOfferings_402656628;
           offeringId: string = ""; maxResults: int = 0; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeReservedElasticsearchInstanceOfferings
  ## Lists available reserved Elasticsearch instance offerings.
  ##   offeringId: string
                                                               ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   
                                                                                                                                                                                                                               ## maxResults: int
                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                               ## :  
                                                                                                                                                                                                                               ## Set 
                                                                                                                                                                                                                               ## this 
                                                                                                                                                                                                                               ## value 
                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                               ## limit 
                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                               ## number 
                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                               ## results 
                                                                                                                                                                                                                               ## returned. 
  ##   
                                                                                                                                                                                                                                            ## nextToken: string
                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                            ## :  
                                                                                                                                                                                                                                            ## Paginated 
                                                                                                                                                                                                                                            ## APIs 
                                                                                                                                                                                                                                            ## accepts 
                                                                                                                                                                                                                                            ## NextToken 
                                                                                                                                                                                                                                            ## input 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## returns 
                                                                                                                                                                                                                                            ## next 
                                                                                                                                                                                                                                            ## page 
                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                            ## provides 
                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                            ## NextToken 
                                                                                                                                                                                                                                            ## output 
                                                                                                                                                                                                                                            ## in 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## response 
                                                                                                                                                                                                                                            ## which 
                                                                                                                                                                                                                                            ## can 
                                                                                                                                                                                                                                            ## be 
                                                                                                                                                                                                                                            ## used 
                                                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                            ## client 
                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                            ## retrieve 
                                                                                                                                                                                                                                            ## more 
                                                                                                                                                                                                                                            ## results. 
  ##   
                                                                                                                                                                                                                                                        ## MaxResults: string
                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                        ## limit
  ##   
                                                                                                                                                                                                                                                                ## NextToken: string
                                                                                                                                                                                                                                                                ##            
                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                ## token
  var query_402656645 = newJObject()
  add(query_402656645, "offeringId", newJString(offeringId))
  add(query_402656645, "maxResults", newJInt(maxResults))
  add(query_402656645, "nextToken", newJString(nextToken))
  add(query_402656645, "MaxResults", newJString(MaxResults))
  add(query_402656645, "NextToken", newJString(NextToken))
  result = call_402656644.call(nil, query_402656645, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_402656628(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_402656629,
    base: "/", makeUrl: url_DescribeReservedElasticsearchInstanceOfferings_402656630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_402656646 = ref object of OpenApiRestCall_402656044
proc url_DescribeReservedElasticsearchInstances_402656648(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstances_402656647(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns information about reserved Elasticsearch instances for this account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Set this value to limit the number of results returned. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Paginated 
                                                                                                            ## APIs 
                                                                                                            ## accepts 
                                                                                                            ## NextToken 
                                                                                                            ## input 
                                                                                                            ## to 
                                                                                                            ## returns 
                                                                                                            ## next 
                                                                                                            ## page 
                                                                                                            ## results 
                                                                                                            ## and 
                                                                                                            ## provides 
                                                                                                            ## a 
                                                                                                            ## NextToken 
                                                                                                            ## output 
                                                                                                            ## in 
                                                                                                            ## the 
                                                                                                            ## response 
                                                                                                            ## which 
                                                                                                            ## can 
                                                                                                            ## be 
                                                                                                            ## used 
                                                                                                            ## by 
                                                                                                            ## the 
                                                                                                            ## client 
                                                                                                            ## to 
                                                                                                            ## retrieve 
                                                                                                            ## more 
                                                                                                            ## results. 
  ##   
                                                                                                                        ## MaxResults: JString
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  ##   
                                                                                                                                ## NextToken: JString
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  ##   
                                                                                                                                        ## reservationId: JString
                                                                                                                                        ##                
                                                                                                                                        ## : 
                                                                                                                                        ## The 
                                                                                                                                        ## reserved 
                                                                                                                                        ## instance 
                                                                                                                                        ## identifier 
                                                                                                                                        ## filter 
                                                                                                                                        ## value. 
                                                                                                                                        ## Use 
                                                                                                                                        ## this 
                                                                                                                                        ## parameter 
                                                                                                                                        ## to 
                                                                                                                                        ## show 
                                                                                                                                        ## only 
                                                                                                                                        ## the 
                                                                                                                                        ## reservation 
                                                                                                                                        ## that 
                                                                                                                                        ## matches 
                                                                                                                                        ## the 
                                                                                                                                        ## specified 
                                                                                                                                        ## reserved 
                                                                                                                                        ## Elasticsearch 
                                                                                                                                        ## instance 
                                                                                                                                        ## ID.
  section = newJObject()
  var valid_402656649 = query.getOrDefault("maxResults")
  valid_402656649 = validateParameter(valid_402656649, JInt, required = false,
                                      default = nil)
  if valid_402656649 != nil:
    section.add "maxResults", valid_402656649
  var valid_402656650 = query.getOrDefault("nextToken")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "nextToken", valid_402656650
  var valid_402656651 = query.getOrDefault("MaxResults")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "MaxResults", valid_402656651
  var valid_402656652 = query.getOrDefault("NextToken")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "NextToken", valid_402656652
  var valid_402656653 = query.getOrDefault("reservationId")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "reservationId", valid_402656653
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
  var valid_402656654 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Security-Token", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Signature")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Signature", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Algorithm", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Date")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Date", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Credential")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Credential", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656661: Call_DescribeReservedElasticsearchInstances_402656646;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
                                                                                         ## 
  let valid = call_402656661.validator(path, query, header, formData, body, _)
  let scheme = call_402656661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656661.makeUrl(scheme.get, call_402656661.host, call_402656661.base,
                                   call_402656661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656661, uri, valid, _)

proc call*(call_402656662: Call_DescribeReservedElasticsearchInstances_402656646;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""; reservationId: string = ""): Recallable =
  ## describeReservedElasticsearchInstances
  ## Returns information about reserved Elasticsearch instances for this account.
  ##   
                                                                                 ## maxResults: int
                                                                                 ##             
                                                                                 ## :  
                                                                                 ## Set 
                                                                                 ## this 
                                                                                 ## value 
                                                                                 ## to 
                                                                                 ## limit 
                                                                                 ## the 
                                                                                 ## number 
                                                                                 ## of 
                                                                                 ## results 
                                                                                 ## returned. 
  ##   
                                                                                              ## nextToken: string
                                                                                              ##            
                                                                                              ## :  
                                                                                              ## Paginated 
                                                                                              ## APIs 
                                                                                              ## accepts 
                                                                                              ## NextToken 
                                                                                              ## input 
                                                                                              ## to 
                                                                                              ## returns 
                                                                                              ## next 
                                                                                              ## page 
                                                                                              ## results 
                                                                                              ## and 
                                                                                              ## provides 
                                                                                              ## a 
                                                                                              ## NextToken 
                                                                                              ## output 
                                                                                              ## in 
                                                                                              ## the 
                                                                                              ## response 
                                                                                              ## which 
                                                                                              ## can 
                                                                                              ## be 
                                                                                              ## used 
                                                                                              ## by 
                                                                                              ## the 
                                                                                              ## client 
                                                                                              ## to 
                                                                                              ## retrieve 
                                                                                              ## more 
                                                                                              ## results. 
  ##   
                                                                                                          ## MaxResults: string
                                                                                                          ##             
                                                                                                          ## : 
                                                                                                          ## Pagination 
                                                                                                          ## limit
  ##   
                                                                                                                  ## NextToken: string
                                                                                                                  ##            
                                                                                                                  ## : 
                                                                                                                  ## Pagination 
                                                                                                                  ## token
  ##   
                                                                                                                          ## reservationId: string
                                                                                                                          ##                
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## reserved 
                                                                                                                          ## instance 
                                                                                                                          ## identifier 
                                                                                                                          ## filter 
                                                                                                                          ## value. 
                                                                                                                          ## Use 
                                                                                                                          ## this 
                                                                                                                          ## parameter 
                                                                                                                          ## to 
                                                                                                                          ## show 
                                                                                                                          ## only 
                                                                                                                          ## the 
                                                                                                                          ## reservation 
                                                                                                                          ## that 
                                                                                                                          ## matches 
                                                                                                                          ## the 
                                                                                                                          ## specified 
                                                                                                                          ## reserved 
                                                                                                                          ## Elasticsearch 
                                                                                                                          ## instance 
                                                                                                                          ## ID.
  var query_402656663 = newJObject()
  add(query_402656663, "maxResults", newJInt(maxResults))
  add(query_402656663, "nextToken", newJString(nextToken))
  add(query_402656663, "MaxResults", newJString(MaxResults))
  add(query_402656663, "NextToken", newJString(NextToken))
  add(query_402656663, "reservationId", newJString(reservationId))
  result = call_402656662.call(nil, query_402656663, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_402656646(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_402656647,
    base: "/", makeUrl: url_DescribeReservedElasticsearchInstances_402656648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_402656664 = ref object of OpenApiRestCall_402656044
proc url_GetCompatibleElasticsearchVersions_402656666(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCompatibleElasticsearchVersions_402656665(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
                                  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_402656667 = query.getOrDefault("domainName")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "domainName", valid_402656667
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
  var valid_402656668 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Security-Token", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Signature")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Signature", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-Algorithm", valid_402656671
  var valid_402656672 = header.getOrDefault("X-Amz-Date")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "X-Amz-Date", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Credential")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Credential", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656675: Call_GetCompatibleElasticsearchVersions_402656664;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
                                                                                         ## 
  let valid = call_402656675.validator(path, query, header, formData, body, _)
  let scheme = call_402656675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656675.makeUrl(scheme.get, call_402656675.host, call_402656675.base,
                                   call_402656675.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656675, uri, valid, _)

proc call*(call_402656676: Call_GetCompatibleElasticsearchVersions_402656664;
           domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   
                                                                                                                                                                                                            ## domainName: string
                                                                                                                                                                                                            ##             
                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                            ## Elasticsearch 
                                                                                                                                                                                                            ## domain. 
                                                                                                                                                                                                            ## Domain 
                                                                                                                                                                                                            ## names 
                                                                                                                                                                                                            ## are 
                                                                                                                                                                                                            ## unique 
                                                                                                                                                                                                            ## across 
                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                            ## domains 
                                                                                                                                                                                                            ## owned 
                                                                                                                                                                                                            ## by 
                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                            ## account 
                                                                                                                                                                                                            ## within 
                                                                                                                                                                                                            ## an 
                                                                                                                                                                                                            ## AWS 
                                                                                                                                                                                                            ## region. 
                                                                                                                                                                                                            ## Domain 
                                                                                                                                                                                                            ## names 
                                                                                                                                                                                                            ## start 
                                                                                                                                                                                                            ## with 
                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                            ## letter 
                                                                                                                                                                                                            ## or 
                                                                                                                                                                                                            ## number 
                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                            ## can 
                                                                                                                                                                                                            ## contain 
                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                            ## following 
                                                                                                                                                                                                            ## characters: 
                                                                                                                                                                                                            ## a-z 
                                                                                                                                                                                                            ## (lowercase), 
                                                                                                                                                                                                            ## 0-9, 
                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                            ## - 
                                                                                                                                                                                                            ## (hyphen).
  var query_402656677 = newJObject()
  add(query_402656677, "domainName", newJString(domainName))
  result = call_402656676.call(nil, query_402656677, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_402656664(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_402656665, base: "/",
    makeUrl: url_GetCompatibleElasticsearchVersions_402656666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_402656678 = ref object of OpenApiRestCall_402656044
proc url_GetUpgradeHistory_402656680(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
                 (kind: VariableSegment, value: "DomainName"),
                 (kind: ConstantSegment, value: "/history")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeHistory_402656679(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656681 = path.getOrDefault("DomainName")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "DomainName", valid_402656681
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Set this value to limit the number of results returned. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Paginated 
                                                                                                            ## APIs 
                                                                                                            ## accepts 
                                                                                                            ## NextToken 
                                                                                                            ## input 
                                                                                                            ## to 
                                                                                                            ## returns 
                                                                                                            ## next 
                                                                                                            ## page 
                                                                                                            ## results 
                                                                                                            ## and 
                                                                                                            ## provides 
                                                                                                            ## a 
                                                                                                            ## NextToken 
                                                                                                            ## output 
                                                                                                            ## in 
                                                                                                            ## the 
                                                                                                            ## response 
                                                                                                            ## which 
                                                                                                            ## can 
                                                                                                            ## be 
                                                                                                            ## used 
                                                                                                            ## by 
                                                                                                            ## the 
                                                                                                            ## client 
                                                                                                            ## to 
                                                                                                            ## retrieve 
                                                                                                            ## more 
                                                                                                            ## results. 
  ##   
                                                                                                                        ## MaxResults: JString
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  ##   
                                                                                                                                ## NextToken: JString
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  section = newJObject()
  var valid_402656682 = query.getOrDefault("maxResults")
  valid_402656682 = validateParameter(valid_402656682, JInt, required = false,
                                      default = nil)
  if valid_402656682 != nil:
    section.add "maxResults", valid_402656682
  var valid_402656683 = query.getOrDefault("nextToken")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "nextToken", valid_402656683
  var valid_402656684 = query.getOrDefault("MaxResults")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "MaxResults", valid_402656684
  var valid_402656685 = query.getOrDefault("NextToken")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "NextToken", valid_402656685
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
  var valid_402656686 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656686 = validateParameter(valid_402656686, JString,
                                      required = false, default = nil)
  if valid_402656686 != nil:
    section.add "X-Amz-Security-Token", valid_402656686
  var valid_402656687 = header.getOrDefault("X-Amz-Signature")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Signature", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Algorithm", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Date")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Date", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Credential")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Credential", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656693: Call_GetUpgradeHistory_402656678;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
                                                                                         ## 
  let valid = call_402656693.validator(path, query, header, formData, body, _)
  let scheme = call_402656693.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656693.makeUrl(scheme.get, call_402656693.host, call_402656693.base,
                                   call_402656693.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656693, uri, valid, _)

proc call*(call_402656694: Call_GetUpgradeHistory_402656678; DomainName: string;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## getUpgradeHistory
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ##   
                                                                                              ## maxResults: int
                                                                                              ##             
                                                                                              ## :  
                                                                                              ## Set 
                                                                                              ## this 
                                                                                              ## value 
                                                                                              ## to 
                                                                                              ## limit 
                                                                                              ## the 
                                                                                              ## number 
                                                                                              ## of 
                                                                                              ## results 
                                                                                              ## returned. 
  ##   
                                                                                                           ## DomainName: string (required)
                                                                                                           ##             
                                                                                                           ## : 
                                                                                                           ## The 
                                                                                                           ## name 
                                                                                                           ## of 
                                                                                                           ## an 
                                                                                                           ## Elasticsearch 
                                                                                                           ## domain. 
                                                                                                           ## Domain 
                                                                                                           ## names 
                                                                                                           ## are 
                                                                                                           ## unique 
                                                                                                           ## across 
                                                                                                           ## the 
                                                                                                           ## domains 
                                                                                                           ## owned 
                                                                                                           ## by 
                                                                                                           ## an 
                                                                                                           ## account 
                                                                                                           ## within 
                                                                                                           ## an 
                                                                                                           ## AWS 
                                                                                                           ## region. 
                                                                                                           ## Domain 
                                                                                                           ## names 
                                                                                                           ## start 
                                                                                                           ## with 
                                                                                                           ## a 
                                                                                                           ## letter 
                                                                                                           ## or 
                                                                                                           ## number 
                                                                                                           ## and 
                                                                                                           ## can 
                                                                                                           ## contain 
                                                                                                           ## the 
                                                                                                           ## following 
                                                                                                           ## characters: 
                                                                                                           ## a-z 
                                                                                                           ## (lowercase), 
                                                                                                           ## 0-9, 
                                                                                                           ## and 
                                                                                                           ## - 
                                                                                                           ## (hyphen).
  ##   
                                                                                                                       ## nextToken: string
                                                                                                                       ##            
                                                                                                                       ## :  
                                                                                                                       ## Paginated 
                                                                                                                       ## APIs 
                                                                                                                       ## accepts 
                                                                                                                       ## NextToken 
                                                                                                                       ## input 
                                                                                                                       ## to 
                                                                                                                       ## returns 
                                                                                                                       ## next 
                                                                                                                       ## page 
                                                                                                                       ## results 
                                                                                                                       ## and 
                                                                                                                       ## provides 
                                                                                                                       ## a 
                                                                                                                       ## NextToken 
                                                                                                                       ## output 
                                                                                                                       ## in 
                                                                                                                       ## the 
                                                                                                                       ## response 
                                                                                                                       ## which 
                                                                                                                       ## can 
                                                                                                                       ## be 
                                                                                                                       ## used 
                                                                                                                       ## by 
                                                                                                                       ## the 
                                                                                                                       ## client 
                                                                                                                       ## to 
                                                                                                                       ## retrieve 
                                                                                                                       ## more 
                                                                                                                       ## results. 
  ##   
                                                                                                                                   ## MaxResults: string
                                                                                                                                   ##             
                                                                                                                                   ## : 
                                                                                                                                   ## Pagination 
                                                                                                                                   ## limit
  ##   
                                                                                                                                           ## NextToken: string
                                                                                                                                           ##            
                                                                                                                                           ## : 
                                                                                                                                           ## Pagination 
                                                                                                                                           ## token
  var path_402656695 = newJObject()
  var query_402656696 = newJObject()
  add(query_402656696, "maxResults", newJInt(maxResults))
  add(path_402656695, "DomainName", newJString(DomainName))
  add(query_402656696, "nextToken", newJString(nextToken))
  add(query_402656696, "MaxResults", newJString(MaxResults))
  add(query_402656696, "NextToken", newJString(NextToken))
  result = call_402656694.call(path_402656695, query_402656696, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_402656678(
    name: "getUpgradeHistory", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_402656679, base: "/",
    makeUrl: url_GetUpgradeHistory_402656680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_402656697 = ref object of OpenApiRestCall_402656044
proc url_GetUpgradeStatus_402656699(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
                 (kind: VariableSegment, value: "DomainName"),
                 (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeStatus_402656698(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DomainName: JString (required)
                                 ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `DomainName` field"
  var valid_402656700 = path.getOrDefault("DomainName")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "DomainName", valid_402656700
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
  var valid_402656701 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "X-Amz-Security-Token", valid_402656701
  var valid_402656702 = header.getOrDefault("X-Amz-Signature")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Signature", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Algorithm", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Date")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Date", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Credential")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Credential", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656708: Call_GetUpgradeStatus_402656697;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
                                                                                         ## 
  let valid = call_402656708.validator(path, query, header, formData, body, _)
  let scheme = call_402656708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656708.makeUrl(scheme.get, call_402656708.host, call_402656708.base,
                                   call_402656708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656708, uri, valid, _)

proc call*(call_402656709: Call_GetUpgradeStatus_402656697; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   
                                                                                                                   ## DomainName: string (required)
                                                                                                                   ##             
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## name 
                                                                                                                   ## of 
                                                                                                                   ## an 
                                                                                                                   ## Elasticsearch 
                                                                                                                   ## domain. 
                                                                                                                   ## Domain 
                                                                                                                   ## names 
                                                                                                                   ## are 
                                                                                                                   ## unique 
                                                                                                                   ## across 
                                                                                                                   ## the 
                                                                                                                   ## domains 
                                                                                                                   ## owned 
                                                                                                                   ## by 
                                                                                                                   ## an 
                                                                                                                   ## account 
                                                                                                                   ## within 
                                                                                                                   ## an 
                                                                                                                   ## AWS 
                                                                                                                   ## region. 
                                                                                                                   ## Domain 
                                                                                                                   ## names 
                                                                                                                   ## start 
                                                                                                                   ## with 
                                                                                                                   ## a 
                                                                                                                   ## letter 
                                                                                                                   ## or 
                                                                                                                   ## number 
                                                                                                                   ## and 
                                                                                                                   ## can 
                                                                                                                   ## contain 
                                                                                                                   ## the 
                                                                                                                   ## following 
                                                                                                                   ## characters: 
                                                                                                                   ## a-z 
                                                                                                                   ## (lowercase), 
                                                                                                                   ## 0-9, 
                                                                                                                   ## and 
                                                                                                                   ## - 
                                                                                                                   ## (hyphen).
  var path_402656710 = newJObject()
  add(path_402656710, "DomainName", newJString(DomainName))
  result = call_402656709.call(path_402656710, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_402656697(
    name: "getUpgradeStatus", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_402656698, base: "/",
    makeUrl: url_GetUpgradeStatus_402656699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_402656711 = ref object of OpenApiRestCall_402656044
proc url_ListDomainNames_402656713(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomainNames_402656712(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
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
  var valid_402656714 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Security-Token", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Signature")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Signature", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656716
  var valid_402656717 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Algorithm", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Date")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Date", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Credential")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Credential", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656721: Call_ListDomainNames_402656711; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
                                                                                         ## 
  let valid = call_402656721.validator(path, query, header, formData, body, _)
  let scheme = call_402656721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656721.makeUrl(scheme.get, call_402656721.host, call_402656721.base,
                                   call_402656721.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656721, uri, valid, _)

proc call*(call_402656722: Call_ListDomainNames_402656711): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_402656722.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_402656711(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/domain", validator: validate_ListDomainNames_402656712,
    base: "/", makeUrl: url_ListDomainNames_402656713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_402656723 = ref object of OpenApiRestCall_402656044
proc url_ListElasticsearchInstanceTypes_402656725(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
         "`ElasticsearchVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypes/"),
                 (kind: VariableSegment, value: "ElasticsearchVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListElasticsearchInstanceTypes_402656724(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ElasticsearchVersion: JString (required)
                                 ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ElasticsearchVersion` field"
  var valid_402656726 = path.getOrDefault("ElasticsearchVersion")
  valid_402656726 = validateParameter(valid_402656726, JString, required = true,
                                      default = nil)
  if valid_402656726 != nil:
    section.add "ElasticsearchVersion", valid_402656726
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Set this value to limit the number of results returned. 
  ##   
                                                                                                            ## domainName: JString
                                                                                                            ##             
                                                                                                            ## : 
                                                                                                            ## The 
                                                                                                            ## name 
                                                                                                            ## of 
                                                                                                            ## an 
                                                                                                            ## Elasticsearch 
                                                                                                            ## domain. 
                                                                                                            ## Domain 
                                                                                                            ## names 
                                                                                                            ## are 
                                                                                                            ## unique 
                                                                                                            ## across 
                                                                                                            ## the 
                                                                                                            ## domains 
                                                                                                            ## owned 
                                                                                                            ## by 
                                                                                                            ## an 
                                                                                                            ## account 
                                                                                                            ## within 
                                                                                                            ## an 
                                                                                                            ## AWS 
                                                                                                            ## region. 
                                                                                                            ## Domain 
                                                                                                            ## names 
                                                                                                            ## start 
                                                                                                            ## with 
                                                                                                            ## a 
                                                                                                            ## letter 
                                                                                                            ## or 
                                                                                                            ## number 
                                                                                                            ## and 
                                                                                                            ## can 
                                                                                                            ## contain 
                                                                                                            ## the 
                                                                                                            ## following 
                                                                                                            ## characters: 
                                                                                                            ## a-z 
                                                                                                            ## (lowercase), 
                                                                                                            ## 0-9, 
                                                                                                            ## and 
                                                                                                            ## - 
                                                                                                            ## (hyphen).
  ##   
                                                                                                                        ## nextToken: JString
                                                                                                                        ##            
                                                                                                                        ## :  
                                                                                                                        ## Paginated 
                                                                                                                        ## APIs 
                                                                                                                        ## accepts 
                                                                                                                        ## NextToken 
                                                                                                                        ## input 
                                                                                                                        ## to 
                                                                                                                        ## returns 
                                                                                                                        ## next 
                                                                                                                        ## page 
                                                                                                                        ## results 
                                                                                                                        ## and 
                                                                                                                        ## provides 
                                                                                                                        ## a 
                                                                                                                        ## NextToken 
                                                                                                                        ## output 
                                                                                                                        ## in 
                                                                                                                        ## the 
                                                                                                                        ## response 
                                                                                                                        ## which 
                                                                                                                        ## can 
                                                                                                                        ## be 
                                                                                                                        ## used 
                                                                                                                        ## by 
                                                                                                                        ## the 
                                                                                                                        ## client 
                                                                                                                        ## to 
                                                                                                                        ## retrieve 
                                                                                                                        ## more 
                                                                                                                        ## results. 
  ##   
                                                                                                                                    ## MaxResults: JString
                                                                                                                                    ##             
                                                                                                                                    ## : 
                                                                                                                                    ## Pagination 
                                                                                                                                    ## limit
  ##   
                                                                                                                                            ## NextToken: JString
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## token
  section = newJObject()
  var valid_402656727 = query.getOrDefault("maxResults")
  valid_402656727 = validateParameter(valid_402656727, JInt, required = false,
                                      default = nil)
  if valid_402656727 != nil:
    section.add "maxResults", valid_402656727
  var valid_402656728 = query.getOrDefault("domainName")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "domainName", valid_402656728
  var valid_402656729 = query.getOrDefault("nextToken")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "nextToken", valid_402656729
  var valid_402656730 = query.getOrDefault("MaxResults")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "MaxResults", valid_402656730
  var valid_402656731 = query.getOrDefault("NextToken")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "NextToken", valid_402656731
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
  var valid_402656732 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Security-Token", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Signature")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Signature", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Algorithm", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Date")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Date", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Credential")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Credential", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656739: Call_ListElasticsearchInstanceTypes_402656723;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
                                                                                         ## 
  let valid = call_402656739.validator(path, query, header, formData, body, _)
  let scheme = call_402656739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656739.makeUrl(scheme.get, call_402656739.host, call_402656739.base,
                                   call_402656739.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656739, uri, valid, _)

proc call*(call_402656740: Call_ListElasticsearchInstanceTypes_402656723;
           ElasticsearchVersion: string; maxResults: int = 0;
           domainName: string = ""; nextToken: string = "";
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listElasticsearchInstanceTypes
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ##   
                                                                                            ## maxResults: int
                                                                                            ##             
                                                                                            ## :  
                                                                                            ## Set 
                                                                                            ## this 
                                                                                            ## value 
                                                                                            ## to 
                                                                                            ## limit 
                                                                                            ## the 
                                                                                            ## number 
                                                                                            ## of 
                                                                                            ## results 
                                                                                            ## returned. 
  ##   
                                                                                                         ## domainName: string
                                                                                                         ##             
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## name 
                                                                                                         ## of 
                                                                                                         ## an 
                                                                                                         ## Elasticsearch 
                                                                                                         ## domain. 
                                                                                                         ## Domain 
                                                                                                         ## names 
                                                                                                         ## are 
                                                                                                         ## unique 
                                                                                                         ## across 
                                                                                                         ## the 
                                                                                                         ## domains 
                                                                                                         ## owned 
                                                                                                         ## by 
                                                                                                         ## an 
                                                                                                         ## account 
                                                                                                         ## within 
                                                                                                         ## an 
                                                                                                         ## AWS 
                                                                                                         ## region. 
                                                                                                         ## Domain 
                                                                                                         ## names 
                                                                                                         ## start 
                                                                                                         ## with 
                                                                                                         ## a 
                                                                                                         ## letter 
                                                                                                         ## or 
                                                                                                         ## number 
                                                                                                         ## and 
                                                                                                         ## can 
                                                                                                         ## contain 
                                                                                                         ## the 
                                                                                                         ## following 
                                                                                                         ## characters: 
                                                                                                         ## a-z 
                                                                                                         ## (lowercase), 
                                                                                                         ## 0-9, 
                                                                                                         ## and 
                                                                                                         ## - 
                                                                                                         ## (hyphen).
  ##   
                                                                                                                     ## ElasticsearchVersion: string (required)
                                                                                                                     ##                       
                                                                                                                     ## : 
                                                                                                                     ## Version 
                                                                                                                     ## of 
                                                                                                                     ## Elasticsearch 
                                                                                                                     ## for 
                                                                                                                     ## which 
                                                                                                                     ## list 
                                                                                                                     ## of 
                                                                                                                     ## supported 
                                                                                                                     ## elasticsearch 
                                                                                                                     ## instance 
                                                                                                                     ## types 
                                                                                                                     ## are 
                                                                                                                     ## needed. 
  ##   
                                                                                                                                ## nextToken: string
                                                                                                                                ##            
                                                                                                                                ## :  
                                                                                                                                ## Paginated 
                                                                                                                                ## APIs 
                                                                                                                                ## accepts 
                                                                                                                                ## NextToken 
                                                                                                                                ## input 
                                                                                                                                ## to 
                                                                                                                                ## returns 
                                                                                                                                ## next 
                                                                                                                                ## page 
                                                                                                                                ## results 
                                                                                                                                ## and 
                                                                                                                                ## provides 
                                                                                                                                ## a 
                                                                                                                                ## NextToken 
                                                                                                                                ## output 
                                                                                                                                ## in 
                                                                                                                                ## the 
                                                                                                                                ## response 
                                                                                                                                ## which 
                                                                                                                                ## can 
                                                                                                                                ## be 
                                                                                                                                ## used 
                                                                                                                                ## by 
                                                                                                                                ## the 
                                                                                                                                ## client 
                                                                                                                                ## to 
                                                                                                                                ## retrieve 
                                                                                                                                ## more 
                                                                                                                                ## results. 
  ##   
                                                                                                                                            ## MaxResults: string
                                                                                                                                            ##             
                                                                                                                                            ## : 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## limit
  ##   
                                                                                                                                                    ## NextToken: string
                                                                                                                                                    ##            
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## token
  var path_402656741 = newJObject()
  var query_402656742 = newJObject()
  add(query_402656742, "maxResults", newJInt(maxResults))
  add(query_402656742, "domainName", newJString(domainName))
  add(path_402656741, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_402656742, "nextToken", newJString(nextToken))
  add(query_402656742, "MaxResults", newJString(MaxResults))
  add(query_402656742, "NextToken", newJString(NextToken))
  result = call_402656740.call(path_402656741, query_402656742, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_402656723(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_402656724, base: "/",
    makeUrl: url_ListElasticsearchInstanceTypes_402656725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_402656743 = ref object of OpenApiRestCall_402656044
proc url_ListElasticsearchVersions_402656745(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListElasticsearchVersions_402656744(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## List all supported Elasticsearch versions
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             :  Set this value to limit the number of results returned. 
  ##   
                                                                                                            ## nextToken: JString
                                                                                                            ##            
                                                                                                            ## :  
                                                                                                            ## Paginated 
                                                                                                            ## APIs 
                                                                                                            ## accepts 
                                                                                                            ## NextToken 
                                                                                                            ## input 
                                                                                                            ## to 
                                                                                                            ## returns 
                                                                                                            ## next 
                                                                                                            ## page 
                                                                                                            ## results 
                                                                                                            ## and 
                                                                                                            ## provides 
                                                                                                            ## a 
                                                                                                            ## NextToken 
                                                                                                            ## output 
                                                                                                            ## in 
                                                                                                            ## the 
                                                                                                            ## response 
                                                                                                            ## which 
                                                                                                            ## can 
                                                                                                            ## be 
                                                                                                            ## used 
                                                                                                            ## by 
                                                                                                            ## the 
                                                                                                            ## client 
                                                                                                            ## to 
                                                                                                            ## retrieve 
                                                                                                            ## more 
                                                                                                            ## results. 
  ##   
                                                                                                                        ## MaxResults: JString
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## limit
  ##   
                                                                                                                                ## NextToken: JString
                                                                                                                                ##            
                                                                                                                                ## : 
                                                                                                                                ## Pagination 
                                                                                                                                ## token
  section = newJObject()
  var valid_402656746 = query.getOrDefault("maxResults")
  valid_402656746 = validateParameter(valid_402656746, JInt, required = false,
                                      default = nil)
  if valid_402656746 != nil:
    section.add "maxResults", valid_402656746
  var valid_402656747 = query.getOrDefault("nextToken")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "nextToken", valid_402656747
  var valid_402656748 = query.getOrDefault("MaxResults")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "MaxResults", valid_402656748
  var valid_402656749 = query.getOrDefault("NextToken")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "NextToken", valid_402656749
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
  var valid_402656750 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Security-Token", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Signature")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Signature", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Algorithm", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Date")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Date", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Credential")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Credential", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656757: Call_ListElasticsearchVersions_402656743;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all supported Elasticsearch versions
                                                                                         ## 
  let valid = call_402656757.validator(path, query, header, formData, body, _)
  let scheme = call_402656757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656757.makeUrl(scheme.get, call_402656757.host, call_402656757.base,
                                   call_402656757.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656757, uri, valid, _)

proc call*(call_402656758: Call_ListElasticsearchVersions_402656743;
           maxResults: int = 0; nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listElasticsearchVersions
  ## List all supported Elasticsearch versions
  ##   maxResults: int
                                              ##             :  Set this value to limit the number of results returned. 
  ##   
                                                                                                                        ## nextToken: string
                                                                                                                        ##            
                                                                                                                        ## :  
                                                                                                                        ## Paginated 
                                                                                                                        ## APIs 
                                                                                                                        ## accepts 
                                                                                                                        ## NextToken 
                                                                                                                        ## input 
                                                                                                                        ## to 
                                                                                                                        ## returns 
                                                                                                                        ## next 
                                                                                                                        ## page 
                                                                                                                        ## results 
                                                                                                                        ## and 
                                                                                                                        ## provides 
                                                                                                                        ## a 
                                                                                                                        ## NextToken 
                                                                                                                        ## output 
                                                                                                                        ## in 
                                                                                                                        ## the 
                                                                                                                        ## response 
                                                                                                                        ## which 
                                                                                                                        ## can 
                                                                                                                        ## be 
                                                                                                                        ## used 
                                                                                                                        ## by 
                                                                                                                        ## the 
                                                                                                                        ## client 
                                                                                                                        ## to 
                                                                                                                        ## retrieve 
                                                                                                                        ## more 
                                                                                                                        ## results. 
  ##   
                                                                                                                                    ## MaxResults: string
                                                                                                                                    ##             
                                                                                                                                    ## : 
                                                                                                                                    ## Pagination 
                                                                                                                                    ## limit
  ##   
                                                                                                                                            ## NextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## token
  var query_402656759 = newJObject()
  add(query_402656759, "maxResults", newJInt(maxResults))
  add(query_402656759, "nextToken", newJString(nextToken))
  add(query_402656759, "MaxResults", newJString(MaxResults))
  add(query_402656759, "NextToken", newJString(NextToken))
  result = call_402656758.call(nil, query_402656759, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_402656743(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_402656744, base: "/",
    makeUrl: url_ListElasticsearchVersions_402656745,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_402656760 = ref object of OpenApiRestCall_402656044
proc url_ListTags_402656762(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_402656761(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all tags for the given Elasticsearch domain.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   arn: JString (required)
                                  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
                                  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" 
                                  ## target="_blank">Identifiers 
                                  ## for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `arn` field"
  var valid_402656763 = query.getOrDefault("arn")
  valid_402656763 = validateParameter(valid_402656763, JString, required = true,
                                      default = nil)
  if valid_402656763 != nil:
    section.add "arn", valid_402656763
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
  var valid_402656764 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Security-Token", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Signature")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Signature", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Algorithm", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Date")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Date", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-Credential")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-Credential", valid_402656769
  var valid_402656770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_ListTags_402656760; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_ListTags_402656760; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
                                                         ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
                                                         ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" 
                                                         ## target="_blank">Identifiers 
                                                         ## for 
                                                         ## IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_402656773 = newJObject()
  add(query_402656773, "arn", newJString(arn))
  result = call_402656772.call(nil, query_402656773, nil, nil, nil)

var listTags* = Call_ListTags_402656760(name: "listTags",
                                        meth: HttpMethod.HttpGet,
                                        host: "es.amazonaws.com",
                                        route: "/2015-01-01/tags/#arn",
                                        validator: validate_ListTags_402656761,
                                        base: "/", makeUrl: url_ListTags_402656762,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_402656774 = ref object of OpenApiRestCall_402656044
proc url_PurchaseReservedElasticsearchInstanceOffering_402656776(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_402656775(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Allows you to purchase reserved Elasticsearch instances.
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
  var valid_402656777 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Security-Token", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Signature")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Signature", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Algorithm", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Date")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Date", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Credential")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Credential", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656783
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

proc call*(call_402656785: Call_PurchaseReservedElasticsearchInstanceOffering_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
                                                                                         ## 
  let valid = call_402656785.validator(path, query, header, formData, body, _)
  let scheme = call_402656785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656785.makeUrl(scheme.get, call_402656785.host, call_402656785.base,
                                   call_402656785.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656785, uri, valid, _)

proc call*(call_402656786: Call_PurchaseReservedElasticsearchInstanceOffering_402656774;
           body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_402656787 = newJObject()
  if body != nil:
    body_402656787 = body
  result = call_402656786.call(nil, nil, nil, nil, body_402656787)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_402656774(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_402656775,
    base: "/", makeUrl: url_PurchaseReservedElasticsearchInstanceOffering_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_402656788 = ref object of OpenApiRestCall_402656044
proc url_RemoveTags_402656790(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTags_402656789(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
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
  var valid_402656791 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Security-Token", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Signature")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Signature", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Algorithm", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Date")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Date", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Credential")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Credential", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656797
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

proc call*(call_402656799: Call_RemoveTags_402656788; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
                                                                                         ## 
  let valid = call_402656799.validator(path, query, header, formData, body, _)
  let scheme = call_402656799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656799.makeUrl(scheme.get, call_402656799.host, call_402656799.base,
                                   call_402656799.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656799, uri, valid, _)

proc call*(call_402656800: Call_RemoveTags_402656788; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   
                                                                               ## body: JObject (required)
  var body_402656801 = newJObject()
  if body != nil:
    body_402656801 = body
  result = call_402656800.call(nil, nil, nil, nil, body_402656801)

var removeTags* = Call_RemoveTags_402656788(name: "removeTags",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/tags-removal", validator: validate_RemoveTags_402656789,
    base: "/", makeUrl: url_RemoveTags_402656790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_402656802 = ref object of OpenApiRestCall_402656044
proc url_StartElasticsearchServiceSoftwareUpdate_402656804(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_402656803(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Schedules a service software update for an Amazon ES domain.
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
  var valid_402656805 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-Security-Token", valid_402656805
  var valid_402656806 = header.getOrDefault("X-Amz-Signature")
  valid_402656806 = validateParameter(valid_402656806, JString,
                                      required = false, default = nil)
  if valid_402656806 != nil:
    section.add "X-Amz-Signature", valid_402656806
  var valid_402656807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656807 = validateParameter(valid_402656807, JString,
                                      required = false, default = nil)
  if valid_402656807 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Algorithm", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Date")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Date", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Credential")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Credential", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656811
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

proc call*(call_402656813: Call_StartElasticsearchServiceSoftwareUpdate_402656802;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
                                                                                         ## 
  let valid = call_402656813.validator(path, query, header, formData, body, _)
  let scheme = call_402656813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656813.makeUrl(scheme.get, call_402656813.host, call_402656813.base,
                                   call_402656813.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656813, uri, valid, _)

proc call*(call_402656814: Call_StartElasticsearchServiceSoftwareUpdate_402656802;
           body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_402656815 = newJObject()
  if body != nil:
    body_402656815 = body
  result = call_402656814.call(nil, nil, nil, nil, body_402656815)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_402656802(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_402656803,
    base: "/", makeUrl: url_StartElasticsearchServiceSoftwareUpdate_402656804,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_402656816 = ref object of OpenApiRestCall_402656044
proc url_UpgradeElasticsearchDomain_402656818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeElasticsearchDomain_402656817(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
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
  var valid_402656819 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Security-Token", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Signature")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Signature", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Algorithm", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Date")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Date", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Credential")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Credential", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656825
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

proc call*(call_402656827: Call_UpgradeElasticsearchDomain_402656816;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
                                                                                         ## 
  let valid = call_402656827.validator(path, query, header, formData, body, _)
  let scheme = call_402656827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656827.makeUrl(scheme.get, call_402656827.host, call_402656827.base,
                                   call_402656827.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656827, uri, valid, _)

proc call*(call_402656828: Call_UpgradeElasticsearchDomain_402656816;
           body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   
                                                                                                                            ## body: JObject (required)
  var body_402656829 = newJObject()
  if body != nil:
    body_402656829 = body
  result = call_402656828.call(nil, nil, nil, nil, body_402656829)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_402656816(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_402656817, base: "/",
    makeUrl: url_UpgradeElasticsearchDomain_402656818,
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