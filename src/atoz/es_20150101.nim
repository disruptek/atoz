
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "es.ap-northeast-1.amazonaws.com",
                           "ap-southeast-1": "es.ap-southeast-1.amazonaws.com",
                           "us-west-2": "es.us-west-2.amazonaws.com",
                           "eu-west-2": "es.eu-west-2.amazonaws.com",
                           "ap-northeast-3": "es.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "es.eu-central-1.amazonaws.com",
                           "us-east-2": "es.us-east-2.amazonaws.com",
                           "us-east-1": "es.us-east-1.amazonaws.com", "cn-northwest-1": "es.cn-northwest-1.amazonaws.com.cn",
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
                           "ca-central-1": "es.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_599705 = ref object of OpenApiRestCall_599368
proc url_AddTags_599707(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTags_599706(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Content-Sha256", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Algorithm")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Algorithm", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Signature")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Signature", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-SignedHeaders", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Credential")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Credential", valid_599825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_AddTags_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_AddTags_599705; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   body: JObject (required)
  var body_599921 = newJObject()
  if body != nil:
    body_599921 = body
  result = call_599920.call(nil, nil, nil, nil, body_599921)

var addTags* = Call_AddTags_599705(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "es.amazonaws.com",
                                route: "/2015-01-01/tags",
                                validator: validate_AddTags_599706, base: "/",
                                url: url_AddTags_599707,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_599960 = ref object of OpenApiRestCall_599368
proc url_CancelElasticsearchServiceSoftwareUpdate_599962(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_599961(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599963 = header.getOrDefault("X-Amz-Date")
  valid_599963 = validateParameter(valid_599963, JString, required = false,
                                 default = nil)
  if valid_599963 != nil:
    section.add "X-Amz-Date", valid_599963
  var valid_599964 = header.getOrDefault("X-Amz-Security-Token")
  valid_599964 = validateParameter(valid_599964, JString, required = false,
                                 default = nil)
  if valid_599964 != nil:
    section.add "X-Amz-Security-Token", valid_599964
  var valid_599965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599965 = validateParameter(valid_599965, JString, required = false,
                                 default = nil)
  if valid_599965 != nil:
    section.add "X-Amz-Content-Sha256", valid_599965
  var valid_599966 = header.getOrDefault("X-Amz-Algorithm")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Algorithm", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Signature")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Signature", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-SignedHeaders", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Credential")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Credential", valid_599969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599971: Call_CancelElasticsearchServiceSoftwareUpdate_599960;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  let valid = call_599971.validator(path, query, header, formData, body)
  let scheme = call_599971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599971.url(scheme.get, call_599971.host, call_599971.base,
                         call_599971.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599971, url, valid)

proc call*(call_599972: Call_CancelElasticsearchServiceSoftwareUpdate_599960;
          body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   body: JObject (required)
  var body_599973 = newJObject()
  if body != nil:
    body_599973 = body
  result = call_599972.call(nil, nil, nil, nil, body_599973)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_599960(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_599961,
    base: "/", url: url_CancelElasticsearchServiceSoftwareUpdate_599962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_599974 = ref object of OpenApiRestCall_599368
proc url_CreateElasticsearchDomain_599976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateElasticsearchDomain_599975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  var valid_599979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599979 = validateParameter(valid_599979, JString, required = false,
                                 default = nil)
  if valid_599979 != nil:
    section.add "X-Amz-Content-Sha256", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Algorithm")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Algorithm", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Signature")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Signature", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-SignedHeaders", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Credential")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Credential", valid_599983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599985: Call_CreateElasticsearchDomain_599974; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  let valid = call_599985.validator(path, query, header, formData, body)
  let scheme = call_599985.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599985.url(scheme.get, call_599985.host, call_599985.base,
                         call_599985.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599985, url, valid)

proc call*(call_599986: Call_CreateElasticsearchDomain_599974; body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_599987 = newJObject()
  if body != nil:
    body_599987 = body
  result = call_599986.call(nil, nil, nil, nil, body_599987)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_599974(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_599975, base: "/",
    url: url_CreateElasticsearchDomain_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_599988 = ref object of OpenApiRestCall_599368
proc url_DescribeElasticsearchDomain_599990(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomain_599989(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600005 = path.getOrDefault("DomainName")
  valid_600005 = validateParameter(valid_600005, JString, required = true,
                                 default = nil)
  if valid_600005 != nil:
    section.add "DomainName", valid_600005
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600006 = header.getOrDefault("X-Amz-Date")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Date", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Security-Token")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Security-Token", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Content-Sha256", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Algorithm")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Algorithm", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Signature")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Signature", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-SignedHeaders", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Credential")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Credential", valid_600012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600013: Call_DescribeElasticsearchDomain_599988; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_600013.validator(path, query, header, formData, body)
  let scheme = call_600013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600013.url(scheme.get, call_600013.host, call_600013.base,
                         call_600013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600013, url, valid)

proc call*(call_600014: Call_DescribeElasticsearchDomain_599988; DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_600015 = newJObject()
  add(path_600015, "DomainName", newJString(DomainName))
  result = call_600014.call(path_600015, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_599988(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_599989, base: "/",
    url: url_DescribeElasticsearchDomain_599990,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_600017 = ref object of OpenApiRestCall_599368
proc url_DeleteElasticsearchDomain_600019(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteElasticsearchDomain_600018(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600020 = path.getOrDefault("DomainName")
  valid_600020 = validateParameter(valid_600020, JString, required = true,
                                 default = nil)
  if valid_600020 != nil:
    section.add "DomainName", valid_600020
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600021 = header.getOrDefault("X-Amz-Date")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Date", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Security-Token")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Security-Token", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Content-Sha256", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Algorithm")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Algorithm", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Signature")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Signature", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-SignedHeaders", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Credential")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Credential", valid_600027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600028: Call_DeleteElasticsearchDomain_600017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  let valid = call_600028.validator(path, query, header, formData, body)
  let scheme = call_600028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600028.url(scheme.get, call_600028.host, call_600028.base,
                         call_600028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600028, url, valid)

proc call*(call_600029: Call_DeleteElasticsearchDomain_600017; DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_600030 = newJObject()
  add(path_600030, "DomainName", newJString(DomainName))
  result = call_600029.call(path_600030, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_600017(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_600018, base: "/",
    url: url_DeleteElasticsearchDomain_600019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_600031 = ref object of OpenApiRestCall_599368
proc url_DeleteElasticsearchServiceRole_600033(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteElasticsearchServiceRole_600032(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600034 = header.getOrDefault("X-Amz-Date")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Date", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Security-Token")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Security-Token", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Content-Sha256", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-Algorithm")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Algorithm", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Signature")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Signature", valid_600038
  var valid_600039 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-SignedHeaders", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Credential")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Credential", valid_600040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600041: Call_DeleteElasticsearchServiceRole_600031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  let valid = call_600041.validator(path, query, header, formData, body)
  let scheme = call_600041.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600041.url(scheme.get, call_600041.host, call_600041.base,
                         call_600041.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600041, url, valid)

proc call*(call_600042: Call_DeleteElasticsearchServiceRole_600031): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_600042.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_600031(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_600032, base: "/",
    url: url_DeleteElasticsearchServiceRole_600033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_600057 = ref object of OpenApiRestCall_599368
proc url_UpdateElasticsearchDomainConfig_600059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateElasticsearchDomainConfig_600058(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600060 = path.getOrDefault("DomainName")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "DomainName", valid_600060
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600061 = header.getOrDefault("X-Amz-Date")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Date", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Security-Token")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Security-Token", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Content-Sha256", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Algorithm")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Algorithm", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Signature")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Signature", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-SignedHeaders", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Credential")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Credential", valid_600067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_UpdateElasticsearchDomainConfig_600057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_UpdateElasticsearchDomainConfig_600057;
          DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   body: JObject (required)
  var path_600071 = newJObject()
  var body_600072 = newJObject()
  add(path_600071, "DomainName", newJString(DomainName))
  if body != nil:
    body_600072 = body
  result = call_600070.call(path_600071, nil, nil, nil, body_600072)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_600057(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_600058, base: "/",
    url: url_UpdateElasticsearchDomainConfig_600059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_600043 = ref object of OpenApiRestCall_599368
proc url_DescribeElasticsearchDomainConfig_600045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchDomainConfig_600044(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600046 = path.getOrDefault("DomainName")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "DomainName", valid_600046
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600047 = header.getOrDefault("X-Amz-Date")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Date", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Security-Token")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Security-Token", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Content-Sha256", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Algorithm")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Algorithm", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Signature")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Signature", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-SignedHeaders", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Credential")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Credential", valid_600053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600054: Call_DescribeElasticsearchDomainConfig_600043;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  let valid = call_600054.validator(path, query, header, formData, body)
  let scheme = call_600054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600054.url(scheme.get, call_600054.host, call_600054.base,
                         call_600054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600054, url, valid)

proc call*(call_600055: Call_DescribeElasticsearchDomainConfig_600043;
          DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_600056 = newJObject()
  add(path_600056, "DomainName", newJString(DomainName))
  result = call_600055.call(path_600056, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_600043(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_600044, base: "/",
    url: url_DescribeElasticsearchDomainConfig_600045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_600073 = ref object of OpenApiRestCall_599368
proc url_DescribeElasticsearchDomains_600075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeElasticsearchDomains_600074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600076 = header.getOrDefault("X-Amz-Date")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Date", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Security-Token")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Security-Token", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Content-Sha256", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Algorithm")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Algorithm", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Signature")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Signature", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-SignedHeaders", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Credential")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Credential", valid_600082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600084: Call_DescribeElasticsearchDomains_600073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_600084.validator(path, query, header, formData, body)
  let scheme = call_600084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600084.url(scheme.get, call_600084.host, call_600084.base,
                         call_600084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600084, url, valid)

proc call*(call_600085: Call_DescribeElasticsearchDomains_600073; body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   body: JObject (required)
  var body_600086 = newJObject()
  if body != nil:
    body_600086 = body
  result = call_600085.call(nil, nil, nil, nil, body_600086)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_600073(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_600074, base: "/",
    url: url_DescribeElasticsearchDomains_600075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_600087 = ref object of OpenApiRestCall_599368
proc url_DescribeElasticsearchInstanceTypeLimits_600089(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
        "`ElasticsearchVersion` is a required path parameter"
  assert "InstanceType" in path, "`InstanceType` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypeLimits/"),
               (kind: VariableSegment, value: "ElasticsearchVersion"),
               (kind: ConstantSegment, value: "/"),
               (kind: VariableSegment, value: "InstanceType")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeElasticsearchInstanceTypeLimits_600088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   InstanceType: JString (required)
  ##               :  The instance type for an Elasticsearch cluster for which Elasticsearch <code> <a>Limits</a> </code> are needed. 
  ##   ElasticsearchVersion: JString (required)
  ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `InstanceType` field"
  var valid_600103 = path.getOrDefault("InstanceType")
  valid_600103 = validateParameter(valid_600103, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_600103 != nil:
    section.add "InstanceType", valid_600103
  var valid_600104 = path.getOrDefault("ElasticsearchVersion")
  valid_600104 = validateParameter(valid_600104, JString, required = true,
                                 default = nil)
  if valid_600104 != nil:
    section.add "ElasticsearchVersion", valid_600104
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_600105 = query.getOrDefault("domainName")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "domainName", valid_600105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600106 = header.getOrDefault("X-Amz-Date")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Date", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Security-Token")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Security-Token", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Content-Sha256", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Algorithm")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Algorithm", valid_600109
  var valid_600110 = header.getOrDefault("X-Amz-Signature")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Signature", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-SignedHeaders", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Credential")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Credential", valid_600112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600113: Call_DescribeElasticsearchInstanceTypeLimits_600087;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  let valid = call_600113.validator(path, query, header, formData, body)
  let scheme = call_600113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600113.url(scheme.get, call_600113.host, call_600113.base,
                         call_600113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600113, url, valid)

proc call*(call_600114: Call_DescribeElasticsearchInstanceTypeLimits_600087;
          ElasticsearchVersion: string;
          InstanceType: string = "m3.medium.elasticsearch"; domainName: string = ""): Recallable =
  ## describeElasticsearchInstanceTypeLimits
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ##   InstanceType: string (required)
  ##               :  The instance type for an Elasticsearch cluster for which Elasticsearch <code> <a>Limits</a> </code> are needed. 
  ##   ElasticsearchVersion: string (required)
  ##                       :  Version of Elasticsearch for which <code> <a>Limits</a> </code> are needed. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_600115 = newJObject()
  var query_600116 = newJObject()
  add(path_600115, "InstanceType", newJString(InstanceType))
  add(path_600115, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_600116, "domainName", newJString(domainName))
  result = call_600114.call(path_600115, query_600116, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_600087(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_600088, base: "/",
    url: url_DescribeElasticsearchInstanceTypeLimits_600089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_600117 = ref object of OpenApiRestCall_599368
proc url_DescribeReservedElasticsearchInstanceOfferings_600119(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_600118(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   offeringId: JString
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600120 = query.getOrDefault("NextToken")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "NextToken", valid_600120
  var valid_600121 = query.getOrDefault("maxResults")
  valid_600121 = validateParameter(valid_600121, JInt, required = false, default = nil)
  if valid_600121 != nil:
    section.add "maxResults", valid_600121
  var valid_600122 = query.getOrDefault("nextToken")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "nextToken", valid_600122
  var valid_600123 = query.getOrDefault("offeringId")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "offeringId", valid_600123
  var valid_600124 = query.getOrDefault("MaxResults")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "MaxResults", valid_600124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600125 = header.getOrDefault("X-Amz-Date")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Date", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Security-Token")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Security-Token", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Content-Sha256", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Algorithm")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Algorithm", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Signature")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Signature", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-SignedHeaders", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Credential")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Credential", valid_600131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600132: Call_DescribeReservedElasticsearchInstanceOfferings_600117;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  let valid = call_600132.validator(path, query, header, formData, body)
  let scheme = call_600132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600132.url(scheme.get, call_600132.host, call_600132.base,
                         call_600132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600132, url, valid)

proc call*(call_600133: Call_DescribeReservedElasticsearchInstanceOfferings_600117;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          offeringId: string = ""; MaxResults: string = ""): Recallable =
  ## describeReservedElasticsearchInstanceOfferings
  ## Lists available reserved Elasticsearch instance offerings.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   offeringId: string
  ##             : The offering identifier filter value. Use this parameter to show only the available offering that matches the specified reservation identifier.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600134 = newJObject()
  add(query_600134, "NextToken", newJString(NextToken))
  add(query_600134, "maxResults", newJInt(maxResults))
  add(query_600134, "nextToken", newJString(nextToken))
  add(query_600134, "offeringId", newJString(offeringId))
  add(query_600134, "MaxResults", newJString(MaxResults))
  result = call_600133.call(nil, query_600134, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_600117(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_600118,
    base: "/", url: url_DescribeReservedElasticsearchInstanceOfferings_600119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_600135 = ref object of OpenApiRestCall_599368
proc url_DescribeReservedElasticsearchInstances_600137(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeReservedElasticsearchInstances_600136(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   reservationId: JString
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600138 = query.getOrDefault("reservationId")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "reservationId", valid_600138
  var valid_600139 = query.getOrDefault("NextToken")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "NextToken", valid_600139
  var valid_600140 = query.getOrDefault("maxResults")
  valid_600140 = validateParameter(valid_600140, JInt, required = false, default = nil)
  if valid_600140 != nil:
    section.add "maxResults", valid_600140
  var valid_600141 = query.getOrDefault("nextToken")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "nextToken", valid_600141
  var valid_600142 = query.getOrDefault("MaxResults")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "MaxResults", valid_600142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600143 = header.getOrDefault("X-Amz-Date")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Date", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Security-Token")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Security-Token", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600150: Call_DescribeReservedElasticsearchInstances_600135;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  let valid = call_600150.validator(path, query, header, formData, body)
  let scheme = call_600150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600150.url(scheme.get, call_600150.host, call_600150.base,
                         call_600150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600150, url, valid)

proc call*(call_600151: Call_DescribeReservedElasticsearchInstances_600135;
          reservationId: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## describeReservedElasticsearchInstances
  ## Returns information about reserved Elasticsearch instances for this account.
  ##   reservationId: string
  ##                : The reserved instance identifier filter value. Use this parameter to show only the reservation that matches the specified reserved Elasticsearch instance ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600152 = newJObject()
  add(query_600152, "reservationId", newJString(reservationId))
  add(query_600152, "NextToken", newJString(NextToken))
  add(query_600152, "maxResults", newJInt(maxResults))
  add(query_600152, "nextToken", newJString(nextToken))
  add(query_600152, "MaxResults", newJString(MaxResults))
  result = call_600151.call(nil, query_600152, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_600135(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_600136, base: "/",
    url: url_DescribeReservedElasticsearchInstances_600137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_600153 = ref object of OpenApiRestCall_599368
proc url_GetCompatibleElasticsearchVersions_600155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCompatibleElasticsearchVersions_600154(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600156 = query.getOrDefault("domainName")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "domainName", valid_600156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600164: Call_GetCompatibleElasticsearchVersions_600153;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  let valid = call_600164.validator(path, query, header, formData, body)
  let scheme = call_600164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600164.url(scheme.get, call_600164.host, call_600164.base,
                         call_600164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600164, url, valid)

proc call*(call_600165: Call_GetCompatibleElasticsearchVersions_600153;
          domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var query_600166 = newJObject()
  add(query_600166, "domainName", newJString(domainName))
  result = call_600165.call(nil, query_600166, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_600153(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_600154, base: "/",
    url: url_GetCompatibleElasticsearchVersions_600155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_600167 = ref object of OpenApiRestCall_599368
proc url_GetUpgradeHistory_600169(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeHistory_600168(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600170 = path.getOrDefault("DomainName")
  valid_600170 = validateParameter(valid_600170, JString, required = true,
                                 default = nil)
  if valid_600170 != nil:
    section.add "DomainName", valid_600170
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600171 = query.getOrDefault("NextToken")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "NextToken", valid_600171
  var valid_600172 = query.getOrDefault("maxResults")
  valid_600172 = validateParameter(valid_600172, JInt, required = false, default = nil)
  if valid_600172 != nil:
    section.add "maxResults", valid_600172
  var valid_600173 = query.getOrDefault("nextToken")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "nextToken", valid_600173
  var valid_600174 = query.getOrDefault("MaxResults")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "MaxResults", valid_600174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600175 = header.getOrDefault("X-Amz-Date")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Date", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Security-Token")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Security-Token", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Content-Sha256", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Algorithm")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Algorithm", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Signature")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Signature", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-SignedHeaders", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Credential")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Credential", valid_600181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600182: Call_GetUpgradeHistory_600167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  let valid = call_600182.validator(path, query, header, formData, body)
  let scheme = call_600182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600182.url(scheme.get, call_600182.host, call_600182.base,
                         call_600182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600182, url, valid)

proc call*(call_600183: Call_GetUpgradeHistory_600167; DomainName: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## getUpgradeHistory
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600184 = newJObject()
  var query_600185 = newJObject()
  add(path_600184, "DomainName", newJString(DomainName))
  add(query_600185, "NextToken", newJString(NextToken))
  add(query_600185, "maxResults", newJInt(maxResults))
  add(query_600185, "nextToken", newJString(nextToken))
  add(query_600185, "MaxResults", newJString(MaxResults))
  result = call_600183.call(path_600184, query_600185, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_600167(name: "getUpgradeHistory",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_600168, base: "/",
    url: url_GetUpgradeHistory_600169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_600186 = ref object of OpenApiRestCall_599368
proc url_GetUpgradeStatus_600188(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUpgradeStatus_600187(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600189 = path.getOrDefault("DomainName")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = nil)
  if valid_600189 != nil:
    section.add "DomainName", valid_600189
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600190 = header.getOrDefault("X-Amz-Date")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Date", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Security-Token")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Security-Token", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600197: Call_GetUpgradeStatus_600186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_GetUpgradeStatus_600186; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_600199 = newJObject()
  add(path_600199, "DomainName", newJString(DomainName))
  result = call_600198.call(path_600199, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_600186(name: "getUpgradeStatus",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_600187, base: "/",
    url: url_GetUpgradeStatus_600188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_600200 = ref object of OpenApiRestCall_599368
proc url_ListDomainNames_600202(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDomainNames_600201(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600210: Call_ListDomainNames_600200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  let valid = call_600210.validator(path, query, header, formData, body)
  let scheme = call_600210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600210.url(scheme.get, call_600210.host, call_600210.base,
                         call_600210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600210, url, valid)

proc call*(call_600211: Call_ListDomainNames_600200): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_600211.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_600200(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com", route: "/2015-01-01/domain",
    validator: validate_ListDomainNames_600201, base: "/", url: url_ListDomainNames_600202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_600212 = ref object of OpenApiRestCall_599368
proc url_ListElasticsearchInstanceTypes_600214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListElasticsearchInstanceTypes_600213(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ElasticsearchVersion: JString (required)
  ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ElasticsearchVersion` field"
  var valid_600215 = path.getOrDefault("ElasticsearchVersion")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "ElasticsearchVersion", valid_600215
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600216 = query.getOrDefault("NextToken")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "NextToken", valid_600216
  var valid_600217 = query.getOrDefault("maxResults")
  valid_600217 = validateParameter(valid_600217, JInt, required = false, default = nil)
  if valid_600217 != nil:
    section.add "maxResults", valid_600217
  var valid_600218 = query.getOrDefault("nextToken")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "nextToken", valid_600218
  var valid_600219 = query.getOrDefault("domainName")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "domainName", valid_600219
  var valid_600220 = query.getOrDefault("MaxResults")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "MaxResults", valid_600220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600221 = header.getOrDefault("X-Amz-Date")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Date", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Security-Token")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Security-Token", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Content-Sha256", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Algorithm")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Algorithm", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Signature")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Signature", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-SignedHeaders", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Credential")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Credential", valid_600227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600228: Call_ListElasticsearchInstanceTypes_600212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  let valid = call_600228.validator(path, query, header, formData, body)
  let scheme = call_600228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600228.url(scheme.get, call_600228.host, call_600228.base,
                         call_600228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600228, url, valid)

proc call*(call_600229: Call_ListElasticsearchInstanceTypes_600212;
          ElasticsearchVersion: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; domainName: string = ""; MaxResults: string = ""): Recallable =
  ## listElasticsearchInstanceTypes
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ##   ElasticsearchVersion: string (required)
  ##                       : Version of Elasticsearch for which list of supported elasticsearch instance types are needed. 
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600230 = newJObject()
  var query_600231 = newJObject()
  add(path_600230, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_600231, "NextToken", newJString(NextToken))
  add(query_600231, "maxResults", newJInt(maxResults))
  add(query_600231, "nextToken", newJString(nextToken))
  add(query_600231, "domainName", newJString(domainName))
  add(query_600231, "MaxResults", newJString(MaxResults))
  result = call_600229.call(path_600230, query_600231, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_600212(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_600213, base: "/",
    url: url_ListElasticsearchInstanceTypes_600214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_600232 = ref object of OpenApiRestCall_599368
proc url_ListElasticsearchVersions_600234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListElasticsearchVersions_600233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all supported Elasticsearch versions
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: JString
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600235 = query.getOrDefault("NextToken")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "NextToken", valid_600235
  var valid_600236 = query.getOrDefault("maxResults")
  valid_600236 = validateParameter(valid_600236, JInt, required = false, default = nil)
  if valid_600236 != nil:
    section.add "maxResults", valid_600236
  var valid_600237 = query.getOrDefault("nextToken")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "nextToken", valid_600237
  var valid_600238 = query.getOrDefault("MaxResults")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "MaxResults", valid_600238
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600239 = header.getOrDefault("X-Amz-Date")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Date", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Security-Token")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Security-Token", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Content-Sha256", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Algorithm")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Algorithm", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Signature")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Signature", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-SignedHeaders", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Credential")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Credential", valid_600245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600246: Call_ListElasticsearchVersions_600232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all supported Elasticsearch versions
  ## 
  let valid = call_600246.validator(path, query, header, formData, body)
  let scheme = call_600246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600246.url(scheme.get, call_600246.host, call_600246.base,
                         call_600246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600246, url, valid)

proc call*(call_600247: Call_ListElasticsearchVersions_600232;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listElasticsearchVersions
  ## List all supported Elasticsearch versions
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             :  Set this value to limit the number of results returned. 
  ##   nextToken: string
  ##            :  Paginated APIs accepts NextToken input to returns next page results and provides a NextToken output in the response which can be used by the client to retrieve more results. 
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600248 = newJObject()
  add(query_600248, "NextToken", newJString(NextToken))
  add(query_600248, "maxResults", newJInt(maxResults))
  add(query_600248, "nextToken", newJString(nextToken))
  add(query_600248, "MaxResults", newJString(MaxResults))
  result = call_600247.call(nil, query_600248, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_600232(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_600233, base: "/",
    url: url_ListElasticsearchVersions_600234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_600249 = ref object of OpenApiRestCall_599368
proc url_ListTags_600251(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTags_600250(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   arn: JString (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `arn` field"
  var valid_600252 = query.getOrDefault("arn")
  valid_600252 = validateParameter(valid_600252, JString, required = true,
                                 default = nil)
  if valid_600252 != nil:
    section.add "arn", valid_600252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600253 = header.getOrDefault("X-Amz-Date")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Date", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Security-Token")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Security-Token", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-Content-Sha256", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Algorithm")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Algorithm", valid_600256
  var valid_600257 = header.getOrDefault("X-Amz-Signature")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Signature", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-SignedHeaders", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Credential")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Credential", valid_600259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600260: Call_ListTags_600249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  let valid = call_600260.validator(path, query, header, formData, body)
  let scheme = call_600260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600260.url(scheme.get, call_600260.host, call_600260.base,
                         call_600260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600260, url, valid)

proc call*(call_600261: Call_ListTags_600249; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_600262 = newJObject()
  add(query_600262, "arn", newJString(arn))
  result = call_600261.call(nil, query_600262, nil, nil, nil)

var listTags* = Call_ListTags_600249(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "es.amazonaws.com",
                                  route: "/2015-01-01/tags/#arn",
                                  validator: validate_ListTags_600250, base: "/",
                                  url: url_ListTags_600251,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_600263 = ref object of OpenApiRestCall_599368
proc url_PurchaseReservedElasticsearchInstanceOffering_600265(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_600264(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600266 = header.getOrDefault("X-Amz-Date")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Date", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Security-Token")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Security-Token", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Content-Sha256", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Algorithm")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Algorithm", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Signature")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Signature", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-SignedHeaders", valid_600271
  var valid_600272 = header.getOrDefault("X-Amz-Credential")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "X-Amz-Credential", valid_600272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600274: Call_PurchaseReservedElasticsearchInstanceOffering_600263;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  let valid = call_600274.validator(path, query, header, formData, body)
  let scheme = call_600274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600274.url(scheme.get, call_600274.host, call_600274.base,
                         call_600274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600274, url, valid)

proc call*(call_600275: Call_PurchaseReservedElasticsearchInstanceOffering_600263;
          body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_600276 = newJObject()
  if body != nil:
    body_600276 = body
  result = call_600275.call(nil, nil, nil, nil, body_600276)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_600263(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_600264,
    base: "/", url: url_PurchaseReservedElasticsearchInstanceOffering_600265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_600277 = ref object of OpenApiRestCall_599368
proc url_RemoveTags_600279(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTags_600278(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600280 = header.getOrDefault("X-Amz-Date")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Date", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Security-Token")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Security-Token", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Content-Sha256", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Algorithm")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Algorithm", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Signature")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Signature", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-SignedHeaders", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Credential")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Credential", valid_600286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600288: Call_RemoveTags_600277; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  let valid = call_600288.validator(path, query, header, formData, body)
  let scheme = call_600288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600288.url(scheme.get, call_600288.host, call_600288.base,
                         call_600288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600288, url, valid)

proc call*(call_600289: Call_RemoveTags_600277; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   body: JObject (required)
  var body_600290 = newJObject()
  if body != nil:
    body_600290 = body
  result = call_600289.call(nil, nil, nil, nil, body_600290)

var removeTags* = Call_RemoveTags_600277(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags-removal",
                                      validator: validate_RemoveTags_600278,
                                      base: "/", url: url_RemoveTags_600279,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_600291 = ref object of OpenApiRestCall_599368
proc url_StartElasticsearchServiceSoftwareUpdate_600293(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_600292(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600294 = header.getOrDefault("X-Amz-Date")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Date", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Security-Token")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Security-Token", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Content-Sha256", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Algorithm")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Algorithm", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Signature")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Signature", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-SignedHeaders", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Credential")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Credential", valid_600300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600302: Call_StartElasticsearchServiceSoftwareUpdate_600291;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_StartElasticsearchServiceSoftwareUpdate_600291;
          body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_600304 = newJObject()
  if body != nil:
    body_600304 = body
  result = call_600303.call(nil, nil, nil, nil, body_600304)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_600291(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_600292, base: "/",
    url: url_StartElasticsearchServiceSoftwareUpdate_600293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_600305 = ref object of OpenApiRestCall_599368
proc url_UpgradeElasticsearchDomain_600307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpgradeElasticsearchDomain_600306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Content-Sha256", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Algorithm")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Algorithm", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Signature")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Signature", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-SignedHeaders", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Credential")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Credential", valid_600314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_UpgradeElasticsearchDomain_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_UpgradeElasticsearchDomain_600305; body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   body: JObject (required)
  var body_600318 = newJObject()
  if body != nil:
    body_600318 = body
  result = call_600317.call(nil, nil, nil, nil, body_600318)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_600305(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_600306, base: "/",
    url: url_UpgradeElasticsearchDomain_600307,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
