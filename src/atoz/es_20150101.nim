
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elasticsearch Service
## version: 2015-01-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Elasticsearch Configuration Service</fullname> <p>Use the Amazon Elasticsearch configuration API to create, configure, and manage Elasticsearch domains.</p> <p>The endpoint for configuration service requests is region-specific: es.<i>region</i>.amazonaws.com. For example, es.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#elasticsearch-service-regions" target="_blank">Regions and Endpoints</a>.</p>
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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTags_600768 = ref object of OpenApiRestCall_600426
proc url_AddTags_600770(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTags_600769(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_AddTags_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_AddTags_600768; body: JsonNode): Recallable =
  ## addTags
  ## Attaches tags to an existing Elasticsearch domain. Tags are a set of case-sensitive key value pairs. An Elasticsearch domain may have up to 10 tags. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-managedomains.html#es-managedomains-awsresorcetagging" target="_blank"> Tagging Amazon Elasticsearch Service Domains for more information.</a>
  ##   body: JObject (required)
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var addTags* = Call_AddTags_600768(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "es.amazonaws.com",
                                route: "/2015-01-01/tags",
                                validator: validate_AddTags_600769, base: "/",
                                url: url_AddTags_600770,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelElasticsearchServiceSoftwareUpdate_601023 = ref object of OpenApiRestCall_600426
proc url_CancelElasticsearchServiceSoftwareUpdate_601025(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelElasticsearchServiceSoftwareUpdate_601024(path: JsonNode;
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
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Content-Sha256", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Algorithm")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Algorithm", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Signature")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Signature", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-SignedHeaders", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Credential")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Credential", valid_601032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_CancelElasticsearchServiceSoftwareUpdate_601023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ## 
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_CancelElasticsearchServiceSoftwareUpdate_601023;
          body: JsonNode): Recallable =
  ## cancelElasticsearchServiceSoftwareUpdate
  ## Cancels a scheduled service software update for an Amazon ES domain. You can only perform this operation before the <code>AutomatedUpdateDate</code> and when the <code>UpdateStatus</code> is in the <code>PENDING_UPDATE</code> state.
  ##   body: JObject (required)
  var body_601036 = newJObject()
  if body != nil:
    body_601036 = body
  result = call_601035.call(nil, nil, nil, nil, body_601036)

var cancelElasticsearchServiceSoftwareUpdate* = Call_CancelElasticsearchServiceSoftwareUpdate_601023(
    name: "cancelElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/serviceSoftwareUpdate/cancel",
    validator: validate_CancelElasticsearchServiceSoftwareUpdate_601024,
    base: "/", url: url_CancelElasticsearchServiceSoftwareUpdate_601025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateElasticsearchDomain_601037 = ref object of OpenApiRestCall_600426
proc url_CreateElasticsearchDomain_601039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateElasticsearchDomain_601038(path: JsonNode; query: JsonNode;
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
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_CreateElasticsearchDomain_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_CreateElasticsearchDomain_601037; body: JsonNode): Recallable =
  ## createElasticsearchDomain
  ## Creates a new Elasticsearch domain. For more information, see <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-createupdatedomains.html#es-createdomains" target="_blank">Creating Elasticsearch Domains</a> in the <i>Amazon Elasticsearch Service Developer Guide</i>.
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var createElasticsearchDomain* = Call_CreateElasticsearchDomain_601037(
    name: "createElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain",
    validator: validate_CreateElasticsearchDomain_601038, base: "/",
    url: url_CreateElasticsearchDomain_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomain_601051 = ref object of OpenApiRestCall_600426
proc url_DescribeElasticsearchDomain_601053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeElasticsearchDomain_601052(path: JsonNode; query: JsonNode;
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
  var valid_601068 = path.getOrDefault("DomainName")
  valid_601068 = validateParameter(valid_601068, JString, required = true,
                                 default = nil)
  if valid_601068 != nil:
    section.add "DomainName", valid_601068
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
  var valid_601069 = header.getOrDefault("X-Amz-Date")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Date", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Security-Token")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Security-Token", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Content-Sha256", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Algorithm")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Algorithm", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Signature")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Signature", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-SignedHeaders", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Credential")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Credential", valid_601075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_DescribeElasticsearchDomain_601051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"))
  result = hook(call_601076, url, valid)

proc call*(call_601077: Call_DescribeElasticsearchDomain_601051; DomainName: string): Recallable =
  ## describeElasticsearchDomain
  ## Returns domain configuration information about the specified Elasticsearch domain, including the domain ID, domain endpoint, and domain ARN.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_601078 = newJObject()
  add(path_601078, "DomainName", newJString(DomainName))
  result = call_601077.call(path_601078, nil, nil, nil, nil)

var describeElasticsearchDomain* = Call_DescribeElasticsearchDomain_601051(
    name: "describeElasticsearchDomain", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DescribeElasticsearchDomain_601052, base: "/",
    url: url_DescribeElasticsearchDomain_601053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchDomain_601080 = ref object of OpenApiRestCall_600426
proc url_DeleteElasticsearchDomain_601082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DeleteElasticsearchDomain_601081(path: JsonNode; query: JsonNode;
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
  var valid_601083 = path.getOrDefault("DomainName")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = nil)
  if valid_601083 != nil:
    section.add "DomainName", valid_601083
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
  var valid_601084 = header.getOrDefault("X-Amz-Date")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Date", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Security-Token")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Security-Token", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Content-Sha256", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Algorithm")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Algorithm", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Signature")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Signature", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-SignedHeaders", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Credential")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Credential", valid_601090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601091: Call_DeleteElasticsearchDomain_601080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ## 
  let valid = call_601091.validator(path, query, header, formData, body)
  let scheme = call_601091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601091.url(scheme.get, call_601091.host, call_601091.base,
                         call_601091.route, valid.getOrDefault("path"))
  result = hook(call_601091, url, valid)

proc call*(call_601092: Call_DeleteElasticsearchDomain_601080; DomainName: string): Recallable =
  ## deleteElasticsearchDomain
  ## Permanently deletes the specified Elasticsearch domain and all of its data. Once a domain is deleted, it cannot be recovered.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_601093 = newJObject()
  add(path_601093, "DomainName", newJString(DomainName))
  result = call_601092.call(path_601093, nil, nil, nil, nil)

var deleteElasticsearchDomain* = Call_DeleteElasticsearchDomain_601080(
    name: "deleteElasticsearchDomain", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}",
    validator: validate_DeleteElasticsearchDomain_601081, base: "/",
    url: url_DeleteElasticsearchDomain_601082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteElasticsearchServiceRole_601094 = ref object of OpenApiRestCall_600426
proc url_DeleteElasticsearchServiceRole_601096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteElasticsearchServiceRole_601095(path: JsonNode;
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
  var valid_601097 = header.getOrDefault("X-Amz-Date")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Date", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Security-Token")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Security-Token", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Content-Sha256", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Algorithm")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Algorithm", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Signature")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Signature", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-SignedHeaders", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Credential")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Credential", valid_601103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601104: Call_DeleteElasticsearchServiceRole_601094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  ## 
  let valid = call_601104.validator(path, query, header, formData, body)
  let scheme = call_601104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601104.url(scheme.get, call_601104.host, call_601104.base,
                         call_601104.route, valid.getOrDefault("path"))
  result = hook(call_601104, url, valid)

proc call*(call_601105: Call_DeleteElasticsearchServiceRole_601094): Recallable =
  ## deleteElasticsearchServiceRole
  ## Deletes the service-linked role that Elasticsearch Service uses to manage and maintain VPC domains. Role deletion will fail if any existing VPC domains use the role. You must delete any such Elasticsearch domains before deleting the role. See <a href="http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-vpc.html#es-enabling-slr" target="_blank">Deleting Elasticsearch Service Role</a> in <i>VPC Endpoints for Amazon Elasticsearch Service Domains</i>.
  result = call_601105.call(nil, nil, nil, nil, nil)

var deleteElasticsearchServiceRole* = Call_DeleteElasticsearchServiceRole_601094(
    name: "deleteElasticsearchServiceRole", meth: HttpMethod.HttpDelete,
    host: "es.amazonaws.com", route: "/2015-01-01/es/role",
    validator: validate_DeleteElasticsearchServiceRole_601095, base: "/",
    url: url_DeleteElasticsearchServiceRole_601096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateElasticsearchDomainConfig_601120 = ref object of OpenApiRestCall_600426
proc url_UpdateElasticsearchDomainConfig_601122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UpdateElasticsearchDomainConfig_601121(path: JsonNode;
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
  var valid_601123 = path.getOrDefault("DomainName")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "DomainName", valid_601123
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
  var valid_601124 = header.getOrDefault("X-Amz-Date")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Date", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Security-Token")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Security-Token", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Content-Sha256", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Algorithm")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Algorithm", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Signature")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Signature", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-SignedHeaders", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Credential")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Credential", valid_601130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_UpdateElasticsearchDomainConfig_601120;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_UpdateElasticsearchDomainConfig_601120;
          DomainName: string; body: JsonNode): Recallable =
  ## updateElasticsearchDomainConfig
  ## Modifies the cluster configuration of the specified Elasticsearch domain, setting as setting the instance type and the number of instances. 
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  ##   body: JObject (required)
  var path_601134 = newJObject()
  var body_601135 = newJObject()
  add(path_601134, "DomainName", newJString(DomainName))
  if body != nil:
    body_601135 = body
  result = call_601133.call(path_601134, nil, nil, nil, body_601135)

var updateElasticsearchDomainConfig* = Call_UpdateElasticsearchDomainConfig_601120(
    name: "updateElasticsearchDomainConfig", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_UpdateElasticsearchDomainConfig_601121, base: "/",
    url: url_UpdateElasticsearchDomainConfig_601122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomainConfig_601106 = ref object of OpenApiRestCall_600426
proc url_DescribeElasticsearchDomainConfig_601108(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/domain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeElasticsearchDomainConfig_601107(path: JsonNode;
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
  var valid_601109 = path.getOrDefault("DomainName")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "DomainName", valid_601109
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
  var valid_601110 = header.getOrDefault("X-Amz-Date")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Date", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Security-Token")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Security-Token", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Content-Sha256", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Algorithm")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Algorithm", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Signature")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Signature", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-SignedHeaders", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Credential")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Credential", valid_601116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601117: Call_DescribeElasticsearchDomainConfig_601106;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ## 
  let valid = call_601117.validator(path, query, header, formData, body)
  let scheme = call_601117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601117.url(scheme.get, call_601117.host, call_601117.base,
                         call_601117.route, valid.getOrDefault("path"))
  result = hook(call_601117, url, valid)

proc call*(call_601118: Call_DescribeElasticsearchDomainConfig_601106;
          DomainName: string): Recallable =
  ## describeElasticsearchDomainConfig
  ## Provides cluster configuration information about the specified Elasticsearch domain, such as the state, creation date, update version, and update date for cluster options.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_601119 = newJObject()
  add(path_601119, "DomainName", newJString(DomainName))
  result = call_601118.call(path_601119, nil, nil, nil, nil)

var describeElasticsearchDomainConfig* = Call_DescribeElasticsearchDomainConfig_601106(
    name: "describeElasticsearchDomainConfig", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain/{DomainName}/config",
    validator: validate_DescribeElasticsearchDomainConfig_601107, base: "/",
    url: url_DescribeElasticsearchDomainConfig_601108,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchDomains_601136 = ref object of OpenApiRestCall_600426
proc url_DescribeElasticsearchDomains_601138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeElasticsearchDomains_601137(path: JsonNode; query: JsonNode;
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
  var valid_601139 = header.getOrDefault("X-Amz-Date")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Date", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Security-Token")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Security-Token", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Content-Sha256", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Algorithm")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Algorithm", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Signature")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Signature", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-SignedHeaders", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Credential")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Credential", valid_601145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601147: Call_DescribeElasticsearchDomains_601136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ## 
  let valid = call_601147.validator(path, query, header, formData, body)
  let scheme = call_601147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601147.url(scheme.get, call_601147.host, call_601147.base,
                         call_601147.route, valid.getOrDefault("path"))
  result = hook(call_601147, url, valid)

proc call*(call_601148: Call_DescribeElasticsearchDomains_601136; body: JsonNode): Recallable =
  ## describeElasticsearchDomains
  ## Returns domain configuration information about the specified Elasticsearch domains, including the domain ID, domain endpoint, and domain ARN.
  ##   body: JObject (required)
  var body_601149 = newJObject()
  if body != nil:
    body_601149 = body
  result = call_601148.call(nil, nil, nil, nil, body_601149)

var describeElasticsearchDomains* = Call_DescribeElasticsearchDomains_601136(
    name: "describeElasticsearchDomains", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/domain-info",
    validator: validate_DescribeElasticsearchDomains_601137, base: "/",
    url: url_DescribeElasticsearchDomains_601138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeElasticsearchInstanceTypeLimits_601150 = ref object of OpenApiRestCall_600426
proc url_DescribeElasticsearchInstanceTypeLimits_601152(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
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
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_DescribeElasticsearchInstanceTypeLimits_601151(path: JsonNode;
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
  var valid_601166 = path.getOrDefault("InstanceType")
  valid_601166 = validateParameter(valid_601166, JString, required = true, default = newJString(
      "m3.medium.elasticsearch"))
  if valid_601166 != nil:
    section.add "InstanceType", valid_601166
  var valid_601167 = path.getOrDefault("ElasticsearchVersion")
  valid_601167 = validateParameter(valid_601167, JString, required = true,
                                 default = nil)
  if valid_601167 != nil:
    section.add "ElasticsearchVersion", valid_601167
  result.add "path", section
  ## parameters in `query` object:
  ##   domainName: JString
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  section = newJObject()
  var valid_601168 = query.getOrDefault("domainName")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "domainName", valid_601168
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
  var valid_601169 = header.getOrDefault("X-Amz-Date")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Date", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Security-Token")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Security-Token", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Content-Sha256", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Algorithm")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Algorithm", valid_601172
  var valid_601173 = header.getOrDefault("X-Amz-Signature")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Signature", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-SignedHeaders", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Credential")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Credential", valid_601175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601176: Call_DescribeElasticsearchInstanceTypeLimits_601150;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Describe Elasticsearch Limits for a given InstanceType and ElasticsearchVersion. When modifying existing Domain, specify the <code> <a>DomainName</a> </code> to know what Limits are supported for modifying. 
  ## 
  let valid = call_601176.validator(path, query, header, formData, body)
  let scheme = call_601176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601176.url(scheme.get, call_601176.host, call_601176.base,
                         call_601176.route, valid.getOrDefault("path"))
  result = hook(call_601176, url, valid)

proc call*(call_601177: Call_DescribeElasticsearchInstanceTypeLimits_601150;
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
  var path_601178 = newJObject()
  var query_601179 = newJObject()
  add(path_601178, "InstanceType", newJString(InstanceType))
  add(path_601178, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_601179, "domainName", newJString(domainName))
  result = call_601177.call(path_601178, query_601179, nil, nil, nil)

var describeElasticsearchInstanceTypeLimits* = Call_DescribeElasticsearchInstanceTypeLimits_601150(
    name: "describeElasticsearchInstanceTypeLimits", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/instanceTypeLimits/{ElasticsearchVersion}/{InstanceType}",
    validator: validate_DescribeElasticsearchInstanceTypeLimits_601151, base: "/",
    url: url_DescribeElasticsearchInstanceTypeLimits_601152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstanceOfferings_601180 = ref object of OpenApiRestCall_600426
proc url_DescribeReservedElasticsearchInstanceOfferings_601182(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReservedElasticsearchInstanceOfferings_601181(
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
  var valid_601183 = query.getOrDefault("NextToken")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "NextToken", valid_601183
  var valid_601184 = query.getOrDefault("maxResults")
  valid_601184 = validateParameter(valid_601184, JInt, required = false, default = nil)
  if valid_601184 != nil:
    section.add "maxResults", valid_601184
  var valid_601185 = query.getOrDefault("nextToken")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "nextToken", valid_601185
  var valid_601186 = query.getOrDefault("offeringId")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "offeringId", valid_601186
  var valid_601187 = query.getOrDefault("MaxResults")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "MaxResults", valid_601187
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
  var valid_601188 = header.getOrDefault("X-Amz-Date")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Date", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Security-Token")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Security-Token", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Content-Sha256", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Algorithm")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Algorithm", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Signature")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Signature", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-SignedHeaders", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Credential")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Credential", valid_601194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601195: Call_DescribeReservedElasticsearchInstanceOfferings_601180;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists available reserved Elasticsearch instance offerings.
  ## 
  let valid = call_601195.validator(path, query, header, formData, body)
  let scheme = call_601195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601195.url(scheme.get, call_601195.host, call_601195.base,
                         call_601195.route, valid.getOrDefault("path"))
  result = hook(call_601195, url, valid)

proc call*(call_601196: Call_DescribeReservedElasticsearchInstanceOfferings_601180;
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
  var query_601197 = newJObject()
  add(query_601197, "NextToken", newJString(NextToken))
  add(query_601197, "maxResults", newJInt(maxResults))
  add(query_601197, "nextToken", newJString(nextToken))
  add(query_601197, "offeringId", newJString(offeringId))
  add(query_601197, "MaxResults", newJString(MaxResults))
  result = call_601196.call(nil, query_601197, nil, nil, nil)

var describeReservedElasticsearchInstanceOfferings* = Call_DescribeReservedElasticsearchInstanceOfferings_601180(
    name: "describeReservedElasticsearchInstanceOfferings",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/reservedInstanceOfferings",
    validator: validate_DescribeReservedElasticsearchInstanceOfferings_601181,
    base: "/", url: url_DescribeReservedElasticsearchInstanceOfferings_601182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservedElasticsearchInstances_601198 = ref object of OpenApiRestCall_600426
proc url_DescribeReservedElasticsearchInstances_601200(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeReservedElasticsearchInstances_601199(path: JsonNode;
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
  var valid_601201 = query.getOrDefault("reservationId")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "reservationId", valid_601201
  var valid_601202 = query.getOrDefault("NextToken")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "NextToken", valid_601202
  var valid_601203 = query.getOrDefault("maxResults")
  valid_601203 = validateParameter(valid_601203, JInt, required = false, default = nil)
  if valid_601203 != nil:
    section.add "maxResults", valid_601203
  var valid_601204 = query.getOrDefault("nextToken")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "nextToken", valid_601204
  var valid_601205 = query.getOrDefault("MaxResults")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "MaxResults", valid_601205
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
  var valid_601206 = header.getOrDefault("X-Amz-Date")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Date", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Security-Token")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Security-Token", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601213: Call_DescribeReservedElasticsearchInstances_601198;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns information about reserved Elasticsearch instances for this account.
  ## 
  let valid = call_601213.validator(path, query, header, formData, body)
  let scheme = call_601213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601213.url(scheme.get, call_601213.host, call_601213.base,
                         call_601213.route, valid.getOrDefault("path"))
  result = hook(call_601213, url, valid)

proc call*(call_601214: Call_DescribeReservedElasticsearchInstances_601198;
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
  var query_601215 = newJObject()
  add(query_601215, "reservationId", newJString(reservationId))
  add(query_601215, "NextToken", newJString(NextToken))
  add(query_601215, "maxResults", newJInt(maxResults))
  add(query_601215, "nextToken", newJString(nextToken))
  add(query_601215, "MaxResults", newJString(MaxResults))
  result = call_601214.call(nil, query_601215, nil, nil, nil)

var describeReservedElasticsearchInstances* = Call_DescribeReservedElasticsearchInstances_601198(
    name: "describeReservedElasticsearchInstances", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/reservedInstances",
    validator: validate_DescribeReservedElasticsearchInstances_601199, base: "/",
    url: url_DescribeReservedElasticsearchInstances_601200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCompatibleElasticsearchVersions_601216 = ref object of OpenApiRestCall_600426
proc url_GetCompatibleElasticsearchVersions_601218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCompatibleElasticsearchVersions_601217(path: JsonNode;
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
  var valid_601219 = query.getOrDefault("domainName")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "domainName", valid_601219
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
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Content-Sha256", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Algorithm")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Algorithm", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Signature")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Signature", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-SignedHeaders", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Credential")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Credential", valid_601226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601227: Call_GetCompatibleElasticsearchVersions_601216;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ## 
  let valid = call_601227.validator(path, query, header, formData, body)
  let scheme = call_601227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601227.url(scheme.get, call_601227.host, call_601227.base,
                         call_601227.route, valid.getOrDefault("path"))
  result = hook(call_601227, url, valid)

proc call*(call_601228: Call_GetCompatibleElasticsearchVersions_601216;
          domainName: string = ""): Recallable =
  ## getCompatibleElasticsearchVersions
  ##  Returns a list of upgrade compatible Elastisearch versions. You can optionally pass a <code> <a>DomainName</a> </code> to get all upgrade compatible Elasticsearch versions for that specific domain. 
  ##   domainName: string
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var query_601229 = newJObject()
  add(query_601229, "domainName", newJString(domainName))
  result = call_601228.call(nil, query_601229, nil, nil, nil)

var getCompatibleElasticsearchVersions* = Call_GetCompatibleElasticsearchVersions_601216(
    name: "getCompatibleElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/compatibleVersions",
    validator: validate_GetCompatibleElasticsearchVersions_601217, base: "/",
    url: url_GetCompatibleElasticsearchVersions_601218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeHistory_601230 = ref object of OpenApiRestCall_600426
proc url_GetUpgradeHistory_601232(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/history")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUpgradeHistory_601231(path: JsonNode; query: JsonNode;
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
  var valid_601233 = path.getOrDefault("DomainName")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = nil)
  if valid_601233 != nil:
    section.add "DomainName", valid_601233
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
  var valid_601234 = query.getOrDefault("NextToken")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "NextToken", valid_601234
  var valid_601235 = query.getOrDefault("maxResults")
  valid_601235 = validateParameter(valid_601235, JInt, required = false, default = nil)
  if valid_601235 != nil:
    section.add "maxResults", valid_601235
  var valid_601236 = query.getOrDefault("nextToken")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "nextToken", valid_601236
  var valid_601237 = query.getOrDefault("MaxResults")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "MaxResults", valid_601237
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
  var valid_601238 = header.getOrDefault("X-Amz-Date")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Date", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Security-Token")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Security-Token", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Content-Sha256", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-Algorithm")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Algorithm", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Signature")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Signature", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-SignedHeaders", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Credential")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Credential", valid_601244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601245: Call_GetUpgradeHistory_601230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the complete history of the last 10 upgrades that were performed on the domain.
  ## 
  let valid = call_601245.validator(path, query, header, formData, body)
  let scheme = call_601245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601245.url(scheme.get, call_601245.host, call_601245.base,
                         call_601245.route, valid.getOrDefault("path"))
  result = hook(call_601245, url, valid)

proc call*(call_601246: Call_GetUpgradeHistory_601230; DomainName: string;
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
  var path_601247 = newJObject()
  var query_601248 = newJObject()
  add(path_601247, "DomainName", newJString(DomainName))
  add(query_601248, "NextToken", newJString(NextToken))
  add(query_601248, "maxResults", newJInt(maxResults))
  add(query_601248, "nextToken", newJString(nextToken))
  add(query_601248, "MaxResults", newJString(MaxResults))
  result = call_601246.call(path_601247, query_601248, nil, nil, nil)

var getUpgradeHistory* = Call_GetUpgradeHistory_601230(name: "getUpgradeHistory",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/history",
    validator: validate_GetUpgradeHistory_601231, base: "/",
    url: url_GetUpgradeHistory_601232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpgradeStatus_601249 = ref object of OpenApiRestCall_600426
proc url_GetUpgradeStatus_601251(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "DomainName" in path, "`DomainName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/upgradeDomain/"),
               (kind: VariableSegment, value: "DomainName"),
               (kind: ConstantSegment, value: "/status")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_GetUpgradeStatus_601250(path: JsonNode; query: JsonNode;
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
  var valid_601252 = path.getOrDefault("DomainName")
  valid_601252 = validateParameter(valid_601252, JString, required = true,
                                 default = nil)
  if valid_601252 != nil:
    section.add "DomainName", valid_601252
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
  var valid_601253 = header.getOrDefault("X-Amz-Date")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Date", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Security-Token")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Security-Token", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Content-Sha256", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Algorithm")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Algorithm", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Signature")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Signature", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-SignedHeaders", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Credential")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Credential", valid_601259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601260: Call_GetUpgradeStatus_601249; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ## 
  let valid = call_601260.validator(path, query, header, formData, body)
  let scheme = call_601260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601260.url(scheme.get, call_601260.host, call_601260.base,
                         call_601260.route, valid.getOrDefault("path"))
  result = hook(call_601260, url, valid)

proc call*(call_601261: Call_GetUpgradeStatus_601249; DomainName: string): Recallable =
  ## getUpgradeStatus
  ## Retrieves the latest status of the last upgrade or upgrade eligibility check that was performed on the domain.
  ##   DomainName: string (required)
  ##             : The name of an Elasticsearch domain. Domain names are unique across the domains owned by an account within an AWS region. Domain names start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen).
  var path_601262 = newJObject()
  add(path_601262, "DomainName", newJString(DomainName))
  result = call_601261.call(path_601262, nil, nil, nil, nil)

var getUpgradeStatus* = Call_GetUpgradeStatus_601249(name: "getUpgradeStatus",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com",
    route: "/2015-01-01/es/upgradeDomain/{DomainName}/status",
    validator: validate_GetUpgradeStatus_601250, base: "/",
    url: url_GetUpgradeStatus_601251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainNames_601263 = ref object of OpenApiRestCall_600426
proc url_ListDomainNames_601265(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDomainNames_601264(path: JsonNode; query: JsonNode;
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
  var valid_601266 = header.getOrDefault("X-Amz-Date")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Date", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Security-Token")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Security-Token", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601273: Call_ListDomainNames_601263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  ## 
  let valid = call_601273.validator(path, query, header, formData, body)
  let scheme = call_601273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601273.url(scheme.get, call_601273.host, call_601273.base,
                         call_601273.route, valid.getOrDefault("path"))
  result = hook(call_601273, url, valid)

proc call*(call_601274: Call_ListDomainNames_601263): Recallable =
  ## listDomainNames
  ## Returns the name of all Elasticsearch domains owned by the current user's account. 
  result = call_601274.call(nil, nil, nil, nil, nil)

var listDomainNames* = Call_ListDomainNames_601263(name: "listDomainNames",
    meth: HttpMethod.HttpGet, host: "es.amazonaws.com", route: "/2015-01-01/domain",
    validator: validate_ListDomainNames_601264, base: "/", url: url_ListDomainNames_601265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchInstanceTypes_601275 = ref object of OpenApiRestCall_600426
proc url_ListElasticsearchInstanceTypes_601277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "ElasticsearchVersion" in path,
        "`ElasticsearchVersion` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-01-01/es/instanceTypes/"),
               (kind: VariableSegment, value: "ElasticsearchVersion")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListElasticsearchInstanceTypes_601276(path: JsonNode;
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
  var valid_601278 = path.getOrDefault("ElasticsearchVersion")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "ElasticsearchVersion", valid_601278
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
  var valid_601279 = query.getOrDefault("NextToken")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "NextToken", valid_601279
  var valid_601280 = query.getOrDefault("maxResults")
  valid_601280 = validateParameter(valid_601280, JInt, required = false, default = nil)
  if valid_601280 != nil:
    section.add "maxResults", valid_601280
  var valid_601281 = query.getOrDefault("nextToken")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "nextToken", valid_601281
  var valid_601282 = query.getOrDefault("domainName")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "domainName", valid_601282
  var valid_601283 = query.getOrDefault("MaxResults")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "MaxResults", valid_601283
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
  var valid_601284 = header.getOrDefault("X-Amz-Date")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Date", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Security-Token")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Security-Token", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Content-Sha256", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Algorithm")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Algorithm", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Signature")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Signature", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-SignedHeaders", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Credential")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Credential", valid_601290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601291: Call_ListElasticsearchInstanceTypes_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all Elasticsearch instance types that are supported for given ElasticsearchVersion
  ## 
  let valid = call_601291.validator(path, query, header, formData, body)
  let scheme = call_601291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601291.url(scheme.get, call_601291.host, call_601291.base,
                         call_601291.route, valid.getOrDefault("path"))
  result = hook(call_601291, url, valid)

proc call*(call_601292: Call_ListElasticsearchInstanceTypes_601275;
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
  var path_601293 = newJObject()
  var query_601294 = newJObject()
  add(path_601293, "ElasticsearchVersion", newJString(ElasticsearchVersion))
  add(query_601294, "NextToken", newJString(NextToken))
  add(query_601294, "maxResults", newJInt(maxResults))
  add(query_601294, "nextToken", newJString(nextToken))
  add(query_601294, "domainName", newJString(domainName))
  add(query_601294, "MaxResults", newJString(MaxResults))
  result = call_601292.call(path_601293, query_601294, nil, nil, nil)

var listElasticsearchInstanceTypes* = Call_ListElasticsearchInstanceTypes_601275(
    name: "listElasticsearchInstanceTypes", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com",
    route: "/2015-01-01/es/instanceTypes/{ElasticsearchVersion}",
    validator: validate_ListElasticsearchInstanceTypes_601276, base: "/",
    url: url_ListElasticsearchInstanceTypes_601277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListElasticsearchVersions_601295 = ref object of OpenApiRestCall_600426
proc url_ListElasticsearchVersions_601297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListElasticsearchVersions_601296(path: JsonNode; query: JsonNode;
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
  var valid_601298 = query.getOrDefault("NextToken")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "NextToken", valid_601298
  var valid_601299 = query.getOrDefault("maxResults")
  valid_601299 = validateParameter(valid_601299, JInt, required = false, default = nil)
  if valid_601299 != nil:
    section.add "maxResults", valid_601299
  var valid_601300 = query.getOrDefault("nextToken")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "nextToken", valid_601300
  var valid_601301 = query.getOrDefault("MaxResults")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "MaxResults", valid_601301
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
  var valid_601302 = header.getOrDefault("X-Amz-Date")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Date", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Security-Token")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Security-Token", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Content-Sha256", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Algorithm")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Algorithm", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Signature")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Signature", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-SignedHeaders", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Credential")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Credential", valid_601308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601309: Call_ListElasticsearchVersions_601295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all supported Elasticsearch versions
  ## 
  let valid = call_601309.validator(path, query, header, formData, body)
  let scheme = call_601309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601309.url(scheme.get, call_601309.host, call_601309.base,
                         call_601309.route, valid.getOrDefault("path"))
  result = hook(call_601309, url, valid)

proc call*(call_601310: Call_ListElasticsearchVersions_601295;
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
  var query_601311 = newJObject()
  add(query_601311, "NextToken", newJString(NextToken))
  add(query_601311, "maxResults", newJInt(maxResults))
  add(query_601311, "nextToken", newJString(nextToken))
  add(query_601311, "MaxResults", newJString(MaxResults))
  result = call_601310.call(nil, query_601311, nil, nil, nil)

var listElasticsearchVersions* = Call_ListElasticsearchVersions_601295(
    name: "listElasticsearchVersions", meth: HttpMethod.HttpGet,
    host: "es.amazonaws.com", route: "/2015-01-01/es/versions",
    validator: validate_ListElasticsearchVersions_601296, base: "/",
    url: url_ListElasticsearchVersions_601297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_601312 = ref object of OpenApiRestCall_600426
proc url_ListTags_601314(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTags_601313(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601315 = query.getOrDefault("arn")
  valid_601315 = validateParameter(valid_601315, JString, required = true,
                                 default = nil)
  if valid_601315 != nil:
    section.add "arn", valid_601315
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
  var valid_601316 = header.getOrDefault("X-Amz-Date")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Date", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Security-Token")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Security-Token", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-Content-Sha256", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Algorithm")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Algorithm", valid_601319
  var valid_601320 = header.getOrDefault("X-Amz-Signature")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "X-Amz-Signature", valid_601320
  var valid_601321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "X-Amz-SignedHeaders", valid_601321
  var valid_601322 = header.getOrDefault("X-Amz-Credential")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Credential", valid_601322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_ListTags_601312; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags for the given Elasticsearch domain.
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"))
  result = hook(call_601323, url, valid)

proc call*(call_601324: Call_ListTags_601312; arn: string): Recallable =
  ## listTags
  ## Returns all tags for the given Elasticsearch domain.
  ##   arn: string (required)
  ##      : The Amazon Resource Name (ARN) of the Elasticsearch domain. See <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?Using_Identifiers.html" target="_blank">Identifiers for IAM Entities</a> in <i>Using AWS Identity and Access Management</i> for more information.
  var query_601325 = newJObject()
  add(query_601325, "arn", newJString(arn))
  result = call_601324.call(nil, query_601325, nil, nil, nil)

var listTags* = Call_ListTags_601312(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "es.amazonaws.com",
                                  route: "/2015-01-01/tags/#arn",
                                  validator: validate_ListTags_601313, base: "/",
                                  url: url_ListTags_601314,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseReservedElasticsearchInstanceOffering_601326 = ref object of OpenApiRestCall_600426
proc url_PurchaseReservedElasticsearchInstanceOffering_601328(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PurchaseReservedElasticsearchInstanceOffering_601327(
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
  var valid_601329 = header.getOrDefault("X-Amz-Date")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Date", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Security-Token")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Security-Token", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Content-Sha256", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Algorithm")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Algorithm", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Signature")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Signature", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-SignedHeaders", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Credential")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Credential", valid_601335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601337: Call_PurchaseReservedElasticsearchInstanceOffering_601326;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Allows you to purchase reserved Elasticsearch instances.
  ## 
  let valid = call_601337.validator(path, query, header, formData, body)
  let scheme = call_601337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601337.url(scheme.get, call_601337.host, call_601337.base,
                         call_601337.route, valid.getOrDefault("path"))
  result = hook(call_601337, url, valid)

proc call*(call_601338: Call_PurchaseReservedElasticsearchInstanceOffering_601326;
          body: JsonNode): Recallable =
  ## purchaseReservedElasticsearchInstanceOffering
  ## Allows you to purchase reserved Elasticsearch instances.
  ##   body: JObject (required)
  var body_601339 = newJObject()
  if body != nil:
    body_601339 = body
  result = call_601338.call(nil, nil, nil, nil, body_601339)

var purchaseReservedElasticsearchInstanceOffering* = Call_PurchaseReservedElasticsearchInstanceOffering_601326(
    name: "purchaseReservedElasticsearchInstanceOffering",
    meth: HttpMethod.HttpPost, host: "es.amazonaws.com",
    route: "/2015-01-01/es/purchaseReservedInstanceOffering",
    validator: validate_PurchaseReservedElasticsearchInstanceOffering_601327,
    base: "/", url: url_PurchaseReservedElasticsearchInstanceOffering_601328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_601340 = ref object of OpenApiRestCall_600426
proc url_RemoveTags_601342(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTags_601341(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601343 = header.getOrDefault("X-Amz-Date")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Date", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Security-Token")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Security-Token", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Content-Sha256", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Algorithm")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Algorithm", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Signature")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Signature", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-SignedHeaders", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Credential")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Credential", valid_601349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601351: Call_RemoveTags_601340; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ## 
  let valid = call_601351.validator(path, query, header, formData, body)
  let scheme = call_601351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601351.url(scheme.get, call_601351.host, call_601351.base,
                         call_601351.route, valid.getOrDefault("path"))
  result = hook(call_601351, url, valid)

proc call*(call_601352: Call_RemoveTags_601340; body: JsonNode): Recallable =
  ## removeTags
  ## Removes the specified set of tags from the specified Elasticsearch domain.
  ##   body: JObject (required)
  var body_601353 = newJObject()
  if body != nil:
    body_601353 = body
  result = call_601352.call(nil, nil, nil, nil, body_601353)

var removeTags* = Call_RemoveTags_601340(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "es.amazonaws.com",
                                      route: "/2015-01-01/tags-removal",
                                      validator: validate_RemoveTags_601341,
                                      base: "/", url: url_RemoveTags_601342,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartElasticsearchServiceSoftwareUpdate_601354 = ref object of OpenApiRestCall_600426
proc url_StartElasticsearchServiceSoftwareUpdate_601356(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StartElasticsearchServiceSoftwareUpdate_601355(path: JsonNode;
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
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601365: Call_StartElasticsearchServiceSoftwareUpdate_601354;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Schedules a service software update for an Amazon ES domain.
  ## 
  let valid = call_601365.validator(path, query, header, formData, body)
  let scheme = call_601365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601365.url(scheme.get, call_601365.host, call_601365.base,
                         call_601365.route, valid.getOrDefault("path"))
  result = hook(call_601365, url, valid)

proc call*(call_601366: Call_StartElasticsearchServiceSoftwareUpdate_601354;
          body: JsonNode): Recallable =
  ## startElasticsearchServiceSoftwareUpdate
  ## Schedules a service software update for an Amazon ES domain.
  ##   body: JObject (required)
  var body_601367 = newJObject()
  if body != nil:
    body_601367 = body
  result = call_601366.call(nil, nil, nil, nil, body_601367)

var startElasticsearchServiceSoftwareUpdate* = Call_StartElasticsearchServiceSoftwareUpdate_601354(
    name: "startElasticsearchServiceSoftwareUpdate", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/serviceSoftwareUpdate/start",
    validator: validate_StartElasticsearchServiceSoftwareUpdate_601355, base: "/",
    url: url_StartElasticsearchServiceSoftwareUpdate_601356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpgradeElasticsearchDomain_601368 = ref object of OpenApiRestCall_600426
proc url_UpgradeElasticsearchDomain_601370(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpgradeElasticsearchDomain_601369(path: JsonNode; query: JsonNode;
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
  var valid_601371 = header.getOrDefault("X-Amz-Date")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Date", valid_601371
  var valid_601372 = header.getOrDefault("X-Amz-Security-Token")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "X-Amz-Security-Token", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_UpgradeElasticsearchDomain_601368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_UpgradeElasticsearchDomain_601368; body: JsonNode): Recallable =
  ## upgradeElasticsearchDomain
  ## Allows you to either upgrade your domain or perform an Upgrade eligibility check to a compatible Elasticsearch version.
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var upgradeElasticsearchDomain* = Call_UpgradeElasticsearchDomain_601368(
    name: "upgradeElasticsearchDomain", meth: HttpMethod.HttpPost,
    host: "es.amazonaws.com", route: "/2015-01-01/es/upgradeDomain",
    validator: validate_UpgradeElasticsearchDomain_601369, base: "/",
    url: url_UpgradeElasticsearchDomain_601370,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
