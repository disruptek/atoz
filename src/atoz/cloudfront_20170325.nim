
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudFront
## version: 2017-03-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudFront</fullname> <p>This is the <i>Amazon CloudFront API Reference</i>. This guide is for developers who need detailed information about CloudFront API actions, data types, and errors. For detailed information about CloudFront features, see the <i>Amazon CloudFront Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudfront/
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn", "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable, Scheme.Https: {
      "cn-northwest-1": "cloudfront.cn-northwest-1.amazonaws.com.cn",
      "cn-north-1": "cloudfront.cn-north-1.amazonaws.com.cn"}.toTable}.toTable
const
  awsServiceName = "cloudfront"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCloudFrontOriginAccessIdentity20170325_601984 = ref object of OpenApiRestCall_601389
proc url_CreateCloudFrontOriginAccessIdentity20170325_601986(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCloudFrontOriginAccessIdentity20170325_601985(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601987 = header.getOrDefault("X-Amz-Signature")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Signature", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Date")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Date", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_CreateCloudFrontOriginAccessIdentity20170325_601984;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_CreateCloudFrontOriginAccessIdentity20170325_601984;
          body: JsonNode): Recallable =
  ## createCloudFrontOriginAccessIdentity20170325
  ## Creates a new origin access identity. If you're using Amazon S3 for your origin, you can use an origin access identity to require users to access your content using a CloudFront URL instead of the Amazon S3 URL. For more information about how to use origin access identities, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html">Serving Private Content through CloudFront</a> in the <i>Amazon CloudFront Developer Guide</i>.
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var createCloudFrontOriginAccessIdentity20170325* = Call_CreateCloudFrontOriginAccessIdentity20170325_601984(
    name: "createCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_CreateCloudFrontOriginAccessIdentity20170325_601985,
    base: "/", url: url_CreateCloudFrontOriginAccessIdentity20170325_601986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCloudFrontOriginAccessIdentities20170325_601727 = ref object of OpenApiRestCall_601389
proc url_ListCloudFrontOriginAccessIdentities20170325_601729(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCloudFrontOriginAccessIdentities20170325_601728(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists origin access identities.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: JString
  ##           : The maximum number of origin access identities you want in the response body. 
  section = newJObject()
  var valid_601841 = query.getOrDefault("Marker")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "Marker", valid_601841
  var valid_601842 = query.getOrDefault("MaxItems")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "MaxItems", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_ListCloudFrontOriginAccessIdentities20170325_601727;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists origin access identities.
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_ListCloudFrontOriginAccessIdentities20170325_601727;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listCloudFrontOriginAccessIdentities20170325
  ## Lists origin access identities.
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of origin access identities. The results include identities in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last identity on that page).
  ##   MaxItems: string
  ##           : The maximum number of origin access identities you want in the response body. 
  var query_601944 = newJObject()
  add(query_601944, "Marker", newJString(Marker))
  add(query_601944, "MaxItems", newJString(MaxItems))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var listCloudFrontOriginAccessIdentities20170325* = Call_ListCloudFrontOriginAccessIdentities20170325_601727(
    name: "listCloudFrontOriginAccessIdentities20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront",
    validator: validate_ListCloudFrontOriginAccessIdentities20170325_601728,
    base: "/", url: url_ListCloudFrontOriginAccessIdentities20170325_601729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistribution20170325_602013 = ref object of OpenApiRestCall_601389
proc url_CreateDistribution20170325_602015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistribution20170325_602014(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602024: Call_CreateDistribution20170325_602013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ## 
  let valid = call_602024.validator(path, query, header, formData, body)
  let scheme = call_602024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602024.url(scheme.get, call_602024.host, call_602024.base,
                         call_602024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602024, url, valid)

proc call*(call_602025: Call_CreateDistribution20170325_602013; body: JsonNode): Recallable =
  ## createDistribution20170325
  ## Creates a new web distribution. Send a <code>POST</code> request to the <code>/<i>CloudFront API version</i>/distribution</code>/<code>distribution ID</code> resource.
  ##   body: JObject (required)
  var body_602026 = newJObject()
  if body != nil:
    body_602026 = body
  result = call_602025.call(nil, nil, nil, nil, body_602026)

var createDistribution20170325* = Call_CreateDistribution20170325_602013(
    name: "createDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_CreateDistribution20170325_602014, base: "/",
    url: url_CreateDistribution20170325_602015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributions20170325_601998 = ref object of OpenApiRestCall_601389
proc url_ListDistributions20170325_602000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDistributions20170325_601999(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: JString
  ##           : The maximum number of distributions you want in the response body.
  section = newJObject()
  var valid_602001 = query.getOrDefault("Marker")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "Marker", valid_602001
  var valid_602002 = query.getOrDefault("MaxItems")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "MaxItems", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Signature")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Signature", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Content-Sha256", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Credential")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Credential", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Security-Token")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Security-Token", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-SignedHeaders", valid_602009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602010: Call_ListDistributions20170325_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List distributions. 
  ## 
  let valid = call_602010.validator(path, query, header, formData, body)
  let scheme = call_602010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602010.url(scheme.get, call_602010.host, call_602010.base,
                         call_602010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602010, url, valid)

proc call*(call_602011: Call_ListDistributions20170325_601998; Marker: string = "";
          MaxItems: string = ""): Recallable =
  ## listDistributions20170325
  ## List distributions. 
  ##   Marker: string
  ##         : Use this when paginating results to indicate where to begin in your list of distributions. The results include distributions in the list that occur after the marker. To get the next page of results, set the <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response (which is also the ID of the last distribution on that page).
  ##   MaxItems: string
  ##           : The maximum number of distributions you want in the response body.
  var query_602012 = newJObject()
  add(query_602012, "Marker", newJString(Marker))
  add(query_602012, "MaxItems", newJString(MaxItems))
  result = call_602011.call(nil, query_602012, nil, nil, nil)

var listDistributions20170325* = Call_ListDistributions20170325_601998(
    name: "listDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution",
    validator: validate_ListDistributions20170325_601999, base: "/",
    url: url_ListDistributions20170325_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDistributionWithTags20170325_602027 = ref object of OpenApiRestCall_601389
proc url_CreateDistributionWithTags20170325_602029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDistributionWithTags20170325_602028(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_602030 = query.getOrDefault("WithTags")
  valid_602030 = validateParameter(valid_602030, JBool, required = true, default = nil)
  if valid_602030 != nil:
    section.add "WithTags", valid_602030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602031 = header.getOrDefault("X-Amz-Signature")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Signature", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Content-Sha256", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Security-Token")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Security-Token", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_CreateDistributionWithTags20170325_602027;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new distribution with tags.
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602039, url, valid)

proc call*(call_602040: Call_CreateDistributionWithTags20170325_602027;
          body: JsonNode; WithTags: bool): Recallable =
  ## createDistributionWithTags20170325
  ## Create a new distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_602041 = newJObject()
  var body_602042 = newJObject()
  if body != nil:
    body_602042 = body
  add(query_602041, "WithTags", newJBool(WithTags))
  result = call_602040.call(nil, query_602041, nil, nil, body_602042)

var createDistributionWithTags20170325* = Call_CreateDistributionWithTags20170325_602027(
    name: "createDistributionWithTags20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution#WithTags",
    validator: validate_CreateDistributionWithTags20170325_602028, base: "/",
    url: url_CreateDistributionWithTags20170325_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInvalidation20170325_602074 = ref object of OpenApiRestCall_601389
proc url_CreateInvalidation20170325_602076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateInvalidation20170325_602075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's id.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602077 = path.getOrDefault("DistributionId")
  valid_602077 = validateParameter(valid_602077, JString, required = true,
                                 default = nil)
  if valid_602077 != nil:
    section.add "DistributionId", valid_602077
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602078 = header.getOrDefault("X-Amz-Signature")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Signature", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Content-Sha256", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Date")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Date", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Credential")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Credential", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Algorithm")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Algorithm", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602086: Call_CreateInvalidation20170325_602074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new invalidation. 
  ## 
  let valid = call_602086.validator(path, query, header, formData, body)
  let scheme = call_602086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602086.url(scheme.get, call_602086.host, call_602086.base,
                         call_602086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602086, url, valid)

proc call*(call_602087: Call_CreateInvalidation20170325_602074;
          DistributionId: string; body: JsonNode): Recallable =
  ## createInvalidation20170325
  ## Create a new invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's id.
  ##   body: JObject (required)
  var path_602088 = newJObject()
  var body_602089 = newJObject()
  add(path_602088, "DistributionId", newJString(DistributionId))
  if body != nil:
    body_602089 = body
  result = call_602087.call(path_602088, nil, nil, nil, body_602089)

var createInvalidation20170325* = Call_CreateInvalidation20170325_602074(
    name: "createInvalidation20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_CreateInvalidation20170325_602075, base: "/",
    url: url_CreateInvalidation20170325_602076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInvalidations20170325_602043 = ref object of OpenApiRestCall_601389
proc url_ListInvalidations20170325_602045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListInvalidations20170325_602044(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists invalidation batches. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602060 = path.getOrDefault("DistributionId")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = nil)
  if valid_602060 != nil:
    section.add "DistributionId", valid_602060
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: JString
  ##           : The maximum number of invalidation batches that you want in the response body.
  section = newJObject()
  var valid_602061 = query.getOrDefault("Marker")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "Marker", valid_602061
  var valid_602062 = query.getOrDefault("MaxItems")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "MaxItems", valid_602062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602063 = header.getOrDefault("X-Amz-Signature")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Signature", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Content-Sha256", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Credential")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Credential", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602070: Call_ListInvalidations20170325_602043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists invalidation batches. 
  ## 
  let valid = call_602070.validator(path, query, header, formData, body)
  let scheme = call_602070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602070.url(scheme.get, call_602070.host, call_602070.base,
                         call_602070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602070, url, valid)

proc call*(call_602071: Call_ListInvalidations20170325_602043;
          DistributionId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listInvalidations20170325
  ## Lists invalidation batches. 
  ##   Marker: string
  ##         : Use this parameter when paginating results to indicate where to begin in your list of invalidation batches. Because the results are returned in decreasing order from most recent to oldest, the most recent results are on the first page, the second page will contain earlier results, and so on. To get the next page of results, set <code>Marker</code> to the value of the <code>NextMarker</code> from the current page's response. This value is the same as the ID of the last invalidation batch on that page. 
  ##   MaxItems: string
  ##           : The maximum number of invalidation batches that you want in the response body.
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  var path_602072 = newJObject()
  var query_602073 = newJObject()
  add(query_602073, "Marker", newJString(Marker))
  add(query_602073, "MaxItems", newJString(MaxItems))
  add(path_602072, "DistributionId", newJString(DistributionId))
  result = call_602071.call(path_602072, query_602073, nil, nil, nil)

var listInvalidations20170325* = Call_ListInvalidations20170325_602043(
    name: "listInvalidations20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation",
    validator: validate_ListInvalidations20170325_602044, base: "/",
    url: url_ListInvalidations20170325_602045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistribution20170325_602105 = ref object of OpenApiRestCall_601389
proc url_CreateStreamingDistribution20170325_602107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistribution20170325_602106(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Signature")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Signature", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Content-Sha256", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Date")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Date", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Credential")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Credential", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Security-Token")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Security-Token", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Algorithm")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Algorithm", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_CreateStreamingDistribution20170325_602105;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602116, url, valid)

proc call*(call_602117: Call_CreateStreamingDistribution20170325_602105;
          body: JsonNode): Recallable =
  ## createStreamingDistribution20170325
  ## <p>Creates a new RMTP distribution. An RTMP distribution is similar to a web distribution, but an RTMP distribution streams media files using the Adobe Real-Time Messaging Protocol (RTMP) instead of serving files using HTTP. </p> <p>To create a new web distribution, submit a <code>POST</code> request to the <i>CloudFront API version</i>/distribution resource. The request body must include a document with a <i>StreamingDistributionConfig</i> element. The response echoes the <code>StreamingDistributionConfig</code> element and returns other information about the RTMP distribution.</p> <p>To get the status of your request, use the <i>GET StreamingDistribution</i> API action. When the value of <code>Enabled</code> is <code>true</code> and the value of <code>Status</code> is <code>Deployed</code>, your distribution is ready. A distribution usually deploys in less than 15 minutes.</p> <p>For more information about web distributions, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-rtmp.html">Working with RTMP Distributions</a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a web distribution or an RTMP distribution, and when you invalidate objects. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values specified.</p> </important>
  ##   body: JObject (required)
  var body_602118 = newJObject()
  if body != nil:
    body_602118 = body
  result = call_602117.call(nil, nil, nil, nil, body_602118)

var createStreamingDistribution20170325* = Call_CreateStreamingDistribution20170325_602105(
    name: "createStreamingDistribution20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/streaming-distribution",
    validator: validate_CreateStreamingDistribution20170325_602106, base: "/",
    url: url_CreateStreamingDistribution20170325_602107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListStreamingDistributions20170325_602090 = ref object of OpenApiRestCall_601389
proc url_ListStreamingDistributions20170325_602092(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListStreamingDistributions20170325_602091(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List streaming distributions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: JString
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  section = newJObject()
  var valid_602093 = query.getOrDefault("Marker")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "Marker", valid_602093
  var valid_602094 = query.getOrDefault("MaxItems")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "MaxItems", valid_602094
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602095 = header.getOrDefault("X-Amz-Signature")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Signature", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Date")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Date", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Credential")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Credential", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Security-Token")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Security-Token", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Algorithm")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Algorithm", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-SignedHeaders", valid_602101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602102: Call_ListStreamingDistributions20170325_602090;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List streaming distributions. 
  ## 
  let valid = call_602102.validator(path, query, header, formData, body)
  let scheme = call_602102.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602102.url(scheme.get, call_602102.host, call_602102.base,
                         call_602102.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602102, url, valid)

proc call*(call_602103: Call_ListStreamingDistributions20170325_602090;
          Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listStreamingDistributions20170325
  ## List streaming distributions. 
  ##   Marker: string
  ##         : The value that you provided for the <code>Marker</code> request parameter.
  ##   MaxItems: string
  ##           : The value that you provided for the <code>MaxItems</code> request parameter.
  var query_602104 = newJObject()
  add(query_602104, "Marker", newJString(Marker))
  add(query_602104, "MaxItems", newJString(MaxItems))
  result = call_602103.call(nil, query_602104, nil, nil, nil)

var listStreamingDistributions20170325* = Call_ListStreamingDistributions20170325_602090(
    name: "listStreamingDistributions20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/streaming-distribution",
    validator: validate_ListStreamingDistributions20170325_602091, base: "/",
    url: url_ListStreamingDistributions20170325_602092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateStreamingDistributionWithTags20170325_602119 = ref object of OpenApiRestCall_601389
proc url_CreateStreamingDistributionWithTags20170325_602121(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateStreamingDistributionWithTags20170325_602120(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new streaming distribution with tags.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   WithTags: JBool (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `WithTags` field"
  var valid_602122 = query.getOrDefault("WithTags")
  valid_602122 = validateParameter(valid_602122, JBool, required = true, default = nil)
  if valid_602122 != nil:
    section.add "WithTags", valid_602122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Content-Sha256", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Date")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Date", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Credential")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Credential", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Security-Token")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Security-Token", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Algorithm")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Algorithm", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602131: Call_CreateStreamingDistributionWithTags20170325_602119;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Create a new streaming distribution with tags.
  ## 
  let valid = call_602131.validator(path, query, header, formData, body)
  let scheme = call_602131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602131.url(scheme.get, call_602131.host, call_602131.base,
                         call_602131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602131, url, valid)

proc call*(call_602132: Call_CreateStreamingDistributionWithTags20170325_602119;
          body: JsonNode; WithTags: bool): Recallable =
  ## createStreamingDistributionWithTags20170325
  ## Create a new streaming distribution with tags.
  ##   body: JObject (required)
  ##   WithTags: bool (required)
  var query_602133 = newJObject()
  var body_602134 = newJObject()
  if body != nil:
    body_602134 = body
  add(query_602133, "WithTags", newJBool(WithTags))
  result = call_602132.call(nil, query_602133, nil, nil, body_602134)

var createStreamingDistributionWithTags20170325* = Call_CreateStreamingDistributionWithTags20170325_602119(
    name: "createStreamingDistributionWithTags20170325",
    meth: HttpMethod.HttpPost, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution#WithTags",
    validator: validate_CreateStreamingDistributionWithTags20170325_602120,
    base: "/", url: url_CreateStreamingDistributionWithTags20170325_602121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentity20170325_602135 = ref object of OpenApiRestCall_601389
proc url_GetCloudFrontOriginAccessIdentity20170325_602137(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetCloudFrontOriginAccessIdentity20170325_602136(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602138 = path.getOrDefault("Id")
  valid_602138 = validateParameter(valid_602138, JString, required = true,
                                 default = nil)
  if valid_602138 != nil:
    section.add "Id", valid_602138
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Content-Sha256", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Security-Token")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Security-Token", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602146: Call_GetCloudFrontOriginAccessIdentity20170325_602135;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the information about an origin access identity. 
  ## 
  let valid = call_602146.validator(path, query, header, formData, body)
  let scheme = call_602146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602146.url(scheme.get, call_602146.host, call_602146.base,
                         call_602146.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602146, url, valid)

proc call*(call_602147: Call_GetCloudFrontOriginAccessIdentity20170325_602135;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentity20170325
  ## Get the information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID.
  var path_602148 = newJObject()
  add(path_602148, "Id", newJString(Id))
  result = call_602147.call(path_602148, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentity20170325* = Call_GetCloudFrontOriginAccessIdentity20170325_602135(
    name: "getCloudFrontOriginAccessIdentity20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_GetCloudFrontOriginAccessIdentity20170325_602136,
    base: "/", url: url_GetCloudFrontOriginAccessIdentity20170325_602137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCloudFrontOriginAccessIdentity20170325_602149 = ref object of OpenApiRestCall_601389
proc url_DeleteCloudFrontOriginAccessIdentity20170325_602151(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCloudFrontOriginAccessIdentity20170325_602150(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The origin access identity's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602152 = path.getOrDefault("Id")
  valid_602152 = validateParameter(valid_602152, JString, required = true,
                                 default = nil)
  if valid_602152 != nil:
    section.add "Id", valid_602152
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header you received from a previous <code>GET</code> or <code>PUT</code> request. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602153 = header.getOrDefault("X-Amz-Signature")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Signature", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Content-Sha256", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Date")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Date", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Credential")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Credential", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("If-Match")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "If-Match", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-SignedHeaders", valid_602160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602161: Call_DeleteCloudFrontOriginAccessIdentity20170325_602149;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Delete an origin access identity. 
  ## 
  let valid = call_602161.validator(path, query, header, formData, body)
  let scheme = call_602161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602161.url(scheme.get, call_602161.host, call_602161.base,
                         call_602161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602161, url, valid)

proc call*(call_602162: Call_DeleteCloudFrontOriginAccessIdentity20170325_602149;
          Id: string): Recallable =
  ## deleteCloudFrontOriginAccessIdentity20170325
  ## Delete an origin access identity. 
  ##   Id: string (required)
  ##     : The origin access identity's ID.
  var path_602163 = newJObject()
  add(path_602163, "Id", newJString(Id))
  result = call_602162.call(path_602163, nil, nil, nil, nil)

var deleteCloudFrontOriginAccessIdentity20170325* = Call_DeleteCloudFrontOriginAccessIdentity20170325_602149(
    name: "deleteCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpDelete, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}",
    validator: validate_DeleteCloudFrontOriginAccessIdentity20170325_602150,
    base: "/", url: url_DeleteCloudFrontOriginAccessIdentity20170325_602151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistribution20170325_602164 = ref object of OpenApiRestCall_601389
proc url_GetDistribution20170325_602166(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDistribution20170325_602165(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602167 = path.getOrDefault("Id")
  valid_602167 = validateParameter(valid_602167, JString, required = true,
                                 default = nil)
  if valid_602167 != nil:
    section.add "Id", valid_602167
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602168 = header.getOrDefault("X-Amz-Signature")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Signature", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Content-Sha256", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Date")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Date", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Credential")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Credential", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Security-Token")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Security-Token", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Algorithm")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Algorithm", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-SignedHeaders", valid_602174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602175: Call_GetDistribution20170325_602164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about a distribution. 
  ## 
  let valid = call_602175.validator(path, query, header, formData, body)
  let scheme = call_602175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602175.url(scheme.get, call_602175.host, call_602175.base,
                         call_602175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602175, url, valid)

proc call*(call_602176: Call_GetDistribution20170325_602164; Id: string): Recallable =
  ## getDistribution20170325
  ## Get the information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_602177 = newJObject()
  add(path_602177, "Id", newJString(Id))
  result = call_602176.call(path_602177, nil, nil, nil, nil)

var getDistribution20170325* = Call_GetDistribution20170325_602164(
    name: "getDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_GetDistribution20170325_602165, base: "/",
    url: url_GetDistribution20170325_602166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDistribution20170325_602178 = ref object of OpenApiRestCall_601389
proc url_DeleteDistribution20170325_602180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDistribution20170325_602179(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602181 = path.getOrDefault("Id")
  valid_602181 = validateParameter(valid_602181, JString, required = true,
                                 default = nil)
  if valid_602181 != nil:
    section.add "Id", valid_602181
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the distribution. For example: <code>E2QWRUHAPOMQZL</code>. 
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602182 = header.getOrDefault("X-Amz-Signature")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Signature", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Content-Sha256", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Date")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Date", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Credential")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Credential", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Security-Token")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Security-Token", valid_602186
  var valid_602187 = header.getOrDefault("If-Match")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "If-Match", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Algorithm")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Algorithm", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-SignedHeaders", valid_602189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602190: Call_DeleteDistribution20170325_602178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a distribution. 
  ## 
  let valid = call_602190.validator(path, query, header, formData, body)
  let scheme = call_602190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602190.url(scheme.get, call_602190.host, call_602190.base,
                         call_602190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602190, url, valid)

proc call*(call_602191: Call_DeleteDistribution20170325_602178; Id: string): Recallable =
  ## deleteDistribution20170325
  ## Delete a distribution. 
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_602192 = newJObject()
  add(path_602192, "Id", newJString(Id))
  result = call_602191.call(path_602192, nil, nil, nil, nil)

var deleteDistribution20170325* = Call_DeleteDistribution20170325_602178(
    name: "deleteDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/distribution/{Id}",
    validator: validate_DeleteDistribution20170325_602179, base: "/",
    url: url_DeleteDistribution20170325_602180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteServiceLinkedRole20170325_602193 = ref object of OpenApiRestCall_601389
proc url_DeleteServiceLinkedRole20170325_602195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "RoleName" in path, "`RoleName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/service-linked-role/"),
               (kind: VariableSegment, value: "RoleName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteServiceLinkedRole20170325_602194(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   RoleName: JString (required)
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `RoleName` field"
  var valid_602196 = path.getOrDefault("RoleName")
  valid_602196 = validateParameter(valid_602196, JString, required = true,
                                 default = nil)
  if valid_602196 != nil:
    section.add "RoleName", valid_602196
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Content-Sha256", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Date")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Date", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Credential")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Credential", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Security-Token")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Security-Token", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Algorithm")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Algorithm", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-SignedHeaders", valid_602203
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_DeleteServiceLinkedRole20170325_602193;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602204, url, valid)

proc call*(call_602205: Call_DeleteServiceLinkedRole20170325_602193;
          RoleName: string): Recallable =
  ## deleteServiceLinkedRole20170325
  ##   RoleName: string (required)
  var path_602206 = newJObject()
  add(path_602206, "RoleName", newJString(RoleName))
  result = call_602205.call(path_602206, nil, nil, nil, nil)

var deleteServiceLinkedRole20170325* = Call_DeleteServiceLinkedRole20170325_602193(
    name: "deleteServiceLinkedRole20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/service-linked-role/{RoleName}",
    validator: validate_DeleteServiceLinkedRole20170325_602194, base: "/",
    url: url_DeleteServiceLinkedRole20170325_602195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistribution20170325_602207 = ref object of OpenApiRestCall_601389
proc url_GetStreamingDistribution20170325_602209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetStreamingDistribution20170325_602208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602210 = path.getOrDefault("Id")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "Id", valid_602210
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_GetStreamingDistribution20170325_602207;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_GetStreamingDistribution20170325_602207; Id: string): Recallable =
  ## getStreamingDistribution20170325
  ## Gets information about a specified RTMP distribution, including the distribution configuration.
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_602220 = newJObject()
  add(path_602220, "Id", newJString(Id))
  result = call_602219.call(path_602220, nil, nil, nil, nil)

var getStreamingDistribution20170325* = Call_GetStreamingDistribution20170325_602207(
    name: "getStreamingDistribution20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_GetStreamingDistribution20170325_602208, base: "/",
    url: url_GetStreamingDistribution20170325_602209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteStreamingDistribution20170325_602221 = ref object of OpenApiRestCall_601389
proc url_DeleteStreamingDistribution20170325_602223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteStreamingDistribution20170325_602222(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602224 = path.getOrDefault("Id")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "Id", valid_602224
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when you disabled the streaming distribution. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Date")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Date", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Credential")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Credential", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Security-Token")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Security-Token", valid_602229
  var valid_602230 = header.getOrDefault("If-Match")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "If-Match", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_DeleteStreamingDistribution20170325_602221;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_DeleteStreamingDistribution20170325_602221; Id: string): Recallable =
  ## deleteStreamingDistribution20170325
  ## <p>Delete a streaming distribution. To delete an RTMP distribution using the CloudFront API, perform the following steps.</p> <p> <b>To delete an RTMP distribution using the CloudFront API</b>:</p> <ol> <li> <p>Disable the RTMP distribution.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to get the current configuration and the <code>Etag</code> header for the distribution. </p> </li> <li> <p>Update the XML document that was returned in the response to your <code>GET Streaming Distribution Config</code> request to change the value of <code>Enabled</code> to <code>false</code>.</p> </li> <li> <p>Submit a <code>PUT Streaming Distribution Config</code> request to update the configuration for your distribution. In the request body, include the XML document that you updated in Step 3. Then set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to the <code>PUT Streaming Distribution Config</code> request to confirm that the distribution was successfully disabled.</p> </li> <li> <p>Submit a <code>GET Streaming Distribution Config</code> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> </li> <li> <p>Submit a <code>DELETE Streaming Distribution</code> request. Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GET Streaming Distribution Config</code> request in Step 2.</p> </li> <li> <p>Review the response to your <code>DELETE Streaming Distribution</code> request to confirm that the distribution was successfully deleted.</p> </li> </ol> <p>For information about deleting a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/HowToDeleteDistribution.html">Deleting a Distribution</a> in the <i>Amazon CloudFront Developer Guide</i>.</p>
  ##   Id: string (required)
  ##     : The distribution ID. 
  var path_602235 = newJObject()
  add(path_602235, "Id", newJString(Id))
  result = call_602234.call(path_602235, nil, nil, nil, nil)

var deleteStreamingDistribution20170325* = Call_DeleteStreamingDistribution20170325_602221(
    name: "deleteStreamingDistribution20170325", meth: HttpMethod.HttpDelete,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}",
    validator: validate_DeleteStreamingDistribution20170325_602222, base: "/",
    url: url_DeleteStreamingDistribution20170325_602223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateCloudFrontOriginAccessIdentity20170325_602250 = ref object of OpenApiRestCall_601389
proc url_UpdateCloudFrontOriginAccessIdentity20170325_602252(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_UpdateCloudFrontOriginAccessIdentity20170325_602251(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602253 = path.getOrDefault("Id")
  valid_602253 = validateParameter(valid_602253, JString, required = true,
                                 default = nil)
  if valid_602253 != nil:
    section.add "Id", valid_602253
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the identity's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602254 = header.getOrDefault("X-Amz-Signature")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Signature", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Content-Sha256", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-Date")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-Date", valid_602256
  var valid_602257 = header.getOrDefault("X-Amz-Credential")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Credential", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Security-Token")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Security-Token", valid_602258
  var valid_602259 = header.getOrDefault("If-Match")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "If-Match", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Algorithm")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Algorithm", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-SignedHeaders", valid_602261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602263: Call_UpdateCloudFrontOriginAccessIdentity20170325_602250;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update an origin access identity. 
  ## 
  let valid = call_602263.validator(path, query, header, formData, body)
  let scheme = call_602263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602263.url(scheme.get, call_602263.host, call_602263.base,
                         call_602263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602263, url, valid)

proc call*(call_602264: Call_UpdateCloudFrontOriginAccessIdentity20170325_602250;
          body: JsonNode; Id: string): Recallable =
  ## updateCloudFrontOriginAccessIdentity20170325
  ## Update an origin access identity. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The identity's id.
  var path_602265 = newJObject()
  var body_602266 = newJObject()
  if body != nil:
    body_602266 = body
  add(path_602265, "Id", newJString(Id))
  result = call_602264.call(path_602265, nil, nil, nil, body_602266)

var updateCloudFrontOriginAccessIdentity20170325* = Call_UpdateCloudFrontOriginAccessIdentity20170325_602250(
    name: "updateCloudFrontOriginAccessIdentity20170325",
    meth: HttpMethod.HttpPut, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_UpdateCloudFrontOriginAccessIdentity20170325_602251,
    base: "/", url: url_UpdateCloudFrontOriginAccessIdentity20170325_602252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCloudFrontOriginAccessIdentityConfig20170325_602236 = ref object of OpenApiRestCall_601389
proc url_GetCloudFrontOriginAccessIdentityConfig20170325_602238(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/origin-access-identity/cloudfront/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_GetCloudFrontOriginAccessIdentityConfig20170325_602237(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode): JsonNode =
  ## Get the configuration information about an origin access identity. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The identity's ID. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602239 = path.getOrDefault("Id")
  valid_602239 = validateParameter(valid_602239, JString, required = true,
                                 default = nil)
  if valid_602239 != nil:
    section.add "Id", valid_602239
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Content-Sha256", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Date")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Date", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Credential")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Credential", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Algorithm")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Algorithm", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602247: Call_GetCloudFrontOriginAccessIdentityConfig20170325_602236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about an origin access identity. 
  ## 
  let valid = call_602247.validator(path, query, header, formData, body)
  let scheme = call_602247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602247.url(scheme.get, call_602247.host, call_602247.base,
                         call_602247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602247, url, valid)

proc call*(call_602248: Call_GetCloudFrontOriginAccessIdentityConfig20170325_602236;
          Id: string): Recallable =
  ## getCloudFrontOriginAccessIdentityConfig20170325
  ## Get the configuration information about an origin access identity. 
  ##   Id: string (required)
  ##     : The identity's ID. 
  var path_602249 = newJObject()
  add(path_602249, "Id", newJString(Id))
  result = call_602248.call(path_602249, nil, nil, nil, nil)

var getCloudFrontOriginAccessIdentityConfig20170325* = Call_GetCloudFrontOriginAccessIdentityConfig20170325_602236(
    name: "getCloudFrontOriginAccessIdentityConfig20170325",
    meth: HttpMethod.HttpGet, host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/origin-access-identity/cloudfront/{Id}/config",
    validator: validate_GetCloudFrontOriginAccessIdentityConfig20170325_602237,
    base: "/", url: url_GetCloudFrontOriginAccessIdentityConfig20170325_602238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDistribution20170325_602281 = ref object of OpenApiRestCall_601389
proc url_UpdateDistribution20170325_602283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_UpdateDistribution20170325_602282(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602284 = path.getOrDefault("Id")
  valid_602284 = validateParameter(valid_602284, JString, required = true,
                                 default = nil)
  if valid_602284 != nil:
    section.add "Id", valid_602284
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Content-Sha256", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Date")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Date", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Credential")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Credential", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Security-Token")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Security-Token", valid_602289
  var valid_602290 = header.getOrDefault("If-Match")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "If-Match", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Algorithm")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Algorithm", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602294: Call_UpdateDistribution20170325_602281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ## 
  let valid = call_602294.validator(path, query, header, formData, body)
  let scheme = call_602294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602294.url(scheme.get, call_602294.host, call_602294.base,
                         call_602294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602294, url, valid)

proc call*(call_602295: Call_UpdateDistribution20170325_602281; body: JsonNode;
          Id: string): Recallable =
  ## updateDistribution20170325
  ## <p>Updates the configuration for a web distribution. Perform the following steps.</p> <p>For information about updating a distribution using the CloudFront console, see <a href="http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html">Creating or Updating a Web Distribution Using the CloudFront Console </a> in the <i>Amazon CloudFront Developer Guide</i>.</p> <p> <b>To update a web distribution using the CloudFront API</b> </p> <ol> <li> <p>Submit a <a>GetDistributionConfig</a> request to get the current configuration and an <code>Etag</code> header for the distribution.</p> <note> <p>If you update the distribution again, you need to get a new <code>Etag</code> header.</p> </note> </li> <li> <p>Update the XML document that was returned in the response to your <code>GetDistributionConfig</code> request to include the desired changes. You can't change the value of <code>CallerReference</code>. If you try to change this value, CloudFront returns an <code>IllegalUpdate</code> error.</p> <important> <p>The new configuration replaces the existing configuration; the values that you specify in an <code>UpdateDistribution</code> request are not merged into the existing configuration. When you add, delete, or replace values in an element that allows multiple values (for example, <code>CNAME</code>), you must specify all of the values that you want to appear in the updated distribution. In addition, you must update the corresponding <code>Quantity</code> element.</p> </important> </li> <li> <p>Submit an <code>UpdateDistribution</code> request to update the configuration for your distribution:</p> <ul> <li> <p>In the request body, include the XML document that you updated in Step 2. The request body must include an XML document with a <code>DistributionConfig</code> element.</p> </li> <li> <p>Set the value of the HTTP <code>If-Match</code> header to the value of the <code>ETag</code> header that CloudFront returned when you submitted the <code>GetDistributionConfig</code> request in Step 1.</p> </li> </ul> </li> <li> <p>Review the response to the <code>UpdateDistribution</code> request to confirm that the configuration was successfully updated.</p> </li> <li> <p>Optional: Submit a <a>GetDistribution</a> request to confirm that your changes have propagated. When propagation is complete, the value of <code>Status</code> is <code>Deployed</code>.</p> <important> <p>Beginning with the 2012-05-05 version of the CloudFront API, we made substantial changes to the format of the XML document that you include in the request body when you create or update a distribution. With previous versions of the API, we discovered that it was too easy to accidentally delete one or more values for an element that accepts multiple values, for example, CNAMEs and trusted signers. Our changes for the 2012-05-05 release are intended to prevent these accidental deletions and to notify you when there's a mismatch between the number of values you say you're specifying in the <code>Quantity</code> element and the number of values you're actually specifying.</p> </important> </li> </ol>
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The distribution's id.
  var path_602296 = newJObject()
  var body_602297 = newJObject()
  if body != nil:
    body_602297 = body
  add(path_602296, "Id", newJString(Id))
  result = call_602295.call(path_602296, nil, nil, nil, body_602297)

var updateDistribution20170325* = Call_UpdateDistribution20170325_602281(
    name: "updateDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_UpdateDistribution20170325_602282, base: "/",
    url: url_UpdateDistribution20170325_602283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDistributionConfig20170325_602267 = ref object of OpenApiRestCall_601389
proc url_GetDistributionConfig20170325_602269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_GetDistributionConfig20170325_602268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602270 = path.getOrDefault("Id")
  valid_602270 = validateParameter(valid_602270, JString, required = true,
                                 default = nil)
  if valid_602270 != nil:
    section.add "Id", valid_602270
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602271 = header.getOrDefault("X-Amz-Signature")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Signature", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Content-Sha256", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Date")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Date", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Credential")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Credential", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Security-Token")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Security-Token", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Algorithm")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Algorithm", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-SignedHeaders", valid_602277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602278: Call_GetDistributionConfig20170325_602267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the configuration information about a distribution. 
  ## 
  let valid = call_602278.validator(path, query, header, formData, body)
  let scheme = call_602278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602278.url(scheme.get, call_602278.host, call_602278.base,
                         call_602278.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602278, url, valid)

proc call*(call_602279: Call_GetDistributionConfig20170325_602267; Id: string): Recallable =
  ## getDistributionConfig20170325
  ## Get the configuration information about a distribution. 
  ##   Id: string (required)
  ##     : The distribution's ID.
  var path_602280 = newJObject()
  add(path_602280, "Id", newJString(Id))
  result = call_602279.call(path_602280, nil, nil, nil, nil)

var getDistributionConfig20170325* = Call_GetDistributionConfig20170325_602267(
    name: "getDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{Id}/config",
    validator: validate_GetDistributionConfig20170325_602268, base: "/",
    url: url_GetDistributionConfig20170325_602269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInvalidation20170325_602298 = ref object of OpenApiRestCall_601389
proc url_GetInvalidation20170325_602300(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "DistributionId" in path, "`DistributionId` is a required path parameter"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-25/distribution/"),
               (kind: VariableSegment, value: "DistributionId"),
               (kind: ConstantSegment, value: "/invalidation/"),
               (kind: VariableSegment, value: "Id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetInvalidation20170325_602299(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the information about an invalidation. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DistributionId: JString (required)
  ##                 : The distribution's ID.
  ##   Id: JString (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DistributionId` field"
  var valid_602301 = path.getOrDefault("DistributionId")
  valid_602301 = validateParameter(valid_602301, JString, required = true,
                                 default = nil)
  if valid_602301 != nil:
    section.add "DistributionId", valid_602301
  var valid_602302 = path.getOrDefault("Id")
  valid_602302 = validateParameter(valid_602302, JString, required = true,
                                 default = nil)
  if valid_602302 != nil:
    section.add "Id", valid_602302
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602303 = header.getOrDefault("X-Amz-Signature")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Signature", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Content-Sha256", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Date")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Date", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Credential")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Credential", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Security-Token")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Security-Token", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Algorithm")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Algorithm", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-SignedHeaders", valid_602309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602310: Call_GetInvalidation20170325_602298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the information about an invalidation. 
  ## 
  let valid = call_602310.validator(path, query, header, formData, body)
  let scheme = call_602310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602310.url(scheme.get, call_602310.host, call_602310.base,
                         call_602310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602310, url, valid)

proc call*(call_602311: Call_GetInvalidation20170325_602298;
          DistributionId: string; Id: string): Recallable =
  ## getInvalidation20170325
  ## Get the information about an invalidation. 
  ##   DistributionId: string (required)
  ##                 : The distribution's ID.
  ##   Id: string (required)
  ##     : The identifier for the invalidation request, for example, <code>IDFDVBD632BHDS5</code>.
  var path_602312 = newJObject()
  add(path_602312, "DistributionId", newJString(DistributionId))
  add(path_602312, "Id", newJString(Id))
  result = call_602311.call(path_602312, nil, nil, nil, nil)

var getInvalidation20170325* = Call_GetInvalidation20170325_602298(
    name: "getInvalidation20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distribution/{DistributionId}/invalidation/{Id}",
    validator: validate_GetInvalidation20170325_602299, base: "/",
    url: url_GetInvalidation20170325_602300, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateStreamingDistribution20170325_602327 = ref object of OpenApiRestCall_601389
proc url_UpdateStreamingDistribution20170325_602329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_UpdateStreamingDistribution20170325_602328(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's id.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602330 = path.getOrDefault("Id")
  valid_602330 = validateParameter(valid_602330, JString, required = true,
                                 default = nil)
  if valid_602330 != nil:
    section.add "Id", valid_602330
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   If-Match: JString
  ##           : The value of the <code>ETag</code> header that you received when retrieving the streaming distribution's configuration. For example: <code>E2QWRUHAPOMQZL</code>.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602331 = header.getOrDefault("X-Amz-Signature")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Signature", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Date")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Date", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Credential")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Credential", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Security-Token")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Security-Token", valid_602335
  var valid_602336 = header.getOrDefault("If-Match")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "If-Match", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Algorithm")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Algorithm", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-SignedHeaders", valid_602338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602340: Call_UpdateStreamingDistribution20170325_602327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Update a streaming distribution. 
  ## 
  let valid = call_602340.validator(path, query, header, formData, body)
  let scheme = call_602340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602340.url(scheme.get, call_602340.host, call_602340.base,
                         call_602340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602340, url, valid)

proc call*(call_602341: Call_UpdateStreamingDistribution20170325_602327;
          body: JsonNode; Id: string): Recallable =
  ## updateStreamingDistribution20170325
  ## Update a streaming distribution. 
  ##   body: JObject (required)
  ##   Id: string (required)
  ##     : The streaming distribution's id.
  var path_602342 = newJObject()
  var body_602343 = newJObject()
  if body != nil:
    body_602343 = body
  add(path_602342, "Id", newJString(Id))
  result = call_602341.call(path_602342, nil, nil, nil, body_602343)

var updateStreamingDistribution20170325* = Call_UpdateStreamingDistribution20170325_602327(
    name: "updateStreamingDistribution20170325", meth: HttpMethod.HttpPut,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_UpdateStreamingDistribution20170325_602328, base: "/",
    url: url_UpdateStreamingDistribution20170325_602329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetStreamingDistributionConfig20170325_602313 = ref object of OpenApiRestCall_601389
proc url_GetStreamingDistributionConfig20170325_602315(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Id" in path, "`Id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/streaming-distribution/"),
               (kind: VariableSegment, value: "Id"),
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

proc validate_GetStreamingDistributionConfig20170325_602314(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get the configuration information about a streaming distribution. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Id: JString (required)
  ##     : The streaming distribution's ID.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Id` field"
  var valid_602316 = path.getOrDefault("Id")
  valid_602316 = validateParameter(valid_602316, JString, required = true,
                                 default = nil)
  if valid_602316 != nil:
    section.add "Id", valid_602316
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602317 = header.getOrDefault("X-Amz-Signature")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Signature", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Content-Sha256", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Date")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Date", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Credential")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Credential", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Security-Token")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Security-Token", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Algorithm")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Algorithm", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-SignedHeaders", valid_602323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602324: Call_GetStreamingDistributionConfig20170325_602313;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Get the configuration information about a streaming distribution. 
  ## 
  let valid = call_602324.validator(path, query, header, formData, body)
  let scheme = call_602324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602324.url(scheme.get, call_602324.host, call_602324.base,
                         call_602324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602324, url, valid)

proc call*(call_602325: Call_GetStreamingDistributionConfig20170325_602313;
          Id: string): Recallable =
  ## getStreamingDistributionConfig20170325
  ## Get the configuration information about a streaming distribution. 
  ##   Id: string (required)
  ##     : The streaming distribution's ID.
  var path_602326 = newJObject()
  add(path_602326, "Id", newJString(Id))
  result = call_602325.call(path_602326, nil, nil, nil, nil)

var getStreamingDistributionConfig20170325* = Call_GetStreamingDistributionConfig20170325_602313(
    name: "getStreamingDistributionConfig20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/streaming-distribution/{Id}/config",
    validator: validate_GetStreamingDistributionConfig20170325_602314, base: "/",
    url: url_GetStreamingDistributionConfig20170325_602315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDistributionsByWebACLId20170325_602344 = ref object of OpenApiRestCall_601389
proc url_ListDistributionsByWebACLId20170325_602346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "WebACLId" in path, "`WebACLId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/2017-03-25/distributionsByWebACLId/"),
               (kind: VariableSegment, value: "WebACLId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDistributionsByWebACLId20170325_602345(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   WebACLId: JString (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `WebACLId` field"
  var valid_602347 = path.getOrDefault("WebACLId")
  valid_602347 = validateParameter(valid_602347, JString, required = true,
                                 default = nil)
  if valid_602347 != nil:
    section.add "WebACLId", valid_602347
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: JString
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  section = newJObject()
  var valid_602348 = query.getOrDefault("Marker")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "Marker", valid_602348
  var valid_602349 = query.getOrDefault("MaxItems")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "MaxItems", valid_602349
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602350 = header.getOrDefault("X-Amz-Signature")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Signature", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Content-Sha256", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Date")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Date", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Credential")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Credential", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Security-Token")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Security-Token", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Algorithm")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Algorithm", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-SignedHeaders", valid_602356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602357: Call_ListDistributionsByWebACLId20170325_602344;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ## 
  let valid = call_602357.validator(path, query, header, formData, body)
  let scheme = call_602357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602357.url(scheme.get, call_602357.host, call_602357.base,
                         call_602357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602357, url, valid)

proc call*(call_602358: Call_ListDistributionsByWebACLId20170325_602344;
          WebACLId: string; Marker: string = ""; MaxItems: string = ""): Recallable =
  ## listDistributionsByWebACLId20170325
  ## List the distributions that are associated with a specified AWS WAF web ACL. 
  ##   Marker: string
  ##         : Use <code>Marker</code> and <code>MaxItems</code> to control pagination of results. If you have more than <code>MaxItems</code> distributions that satisfy the request, the response includes a <code>NextMarker</code> element. To get the next page of results, submit another request. For the value of <code>Marker</code>, specify the value of <code>NextMarker</code> from the last response. (For the first request, omit <code>Marker</code>.) 
  ##   MaxItems: string
  ##           : The maximum number of distributions that you want CloudFront to return in the response body. The maximum and default values are both 100.
  ##   WebACLId: string (required)
  ##           : The ID of the AWS WAF web ACL that you want to list the associated distributions. If you specify "null" for the ID, the request returns a list of the distributions that aren't associated with a web ACL. 
  var path_602359 = newJObject()
  var query_602360 = newJObject()
  add(query_602360, "Marker", newJString(Marker))
  add(query_602360, "MaxItems", newJString(MaxItems))
  add(path_602359, "WebACLId", newJString(WebACLId))
  result = call_602358.call(path_602359, query_602360, nil, nil, nil)

var listDistributionsByWebACLId20170325* = Call_ListDistributionsByWebACLId20170325_602344(
    name: "listDistributionsByWebACLId20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/distributionsByWebACLId/{WebACLId}",
    validator: validate_ListDistributionsByWebACLId20170325_602345, base: "/",
    url: url_ListDistributionsByWebACLId20170325_602346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource20170325_602361 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource20170325_602363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource20170325_602362(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List tags for a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602364 = query.getOrDefault("Resource")
  valid_602364 = validateParameter(valid_602364, JString, required = true,
                                 default = nil)
  if valid_602364 != nil:
    section.add "Resource", valid_602364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602365 = header.getOrDefault("X-Amz-Signature")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Signature", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Content-Sha256", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Credential")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Credential", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Security-Token")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Security-Token", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Algorithm")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Algorithm", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-SignedHeaders", valid_602371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602372: Call_ListTagsForResource20170325_602361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List tags for a CloudFront resource.
  ## 
  let valid = call_602372.validator(path, query, header, formData, body)
  let scheme = call_602372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602372.url(scheme.get, call_602372.host, call_602372.base,
                         call_602372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602372, url, valid)

proc call*(call_602373: Call_ListTagsForResource20170325_602361; Resource: string): Recallable =
  ## listTagsForResource20170325
  ## List tags for a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  var query_602374 = newJObject()
  add(query_602374, "Resource", newJString(Resource))
  result = call_602373.call(nil, query_602374, nil, nil, nil)

var listTagsForResource20170325* = Call_ListTagsForResource20170325_602361(
    name: "listTagsForResource20170325", meth: HttpMethod.HttpGet,
    host: "cloudfront.amazonaws.com", route: "/2017-03-25/tagging#Resource",
    validator: validate_ListTagsForResource20170325_602362, base: "/",
    url: url_ListTagsForResource20170325_602363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource20170325_602375 = ref object of OpenApiRestCall_601389
proc url_TagResource20170325_602377(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource20170325_602376(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Add tags to a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602378 = query.getOrDefault("Resource")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = nil)
  if valid_602378 != nil:
    section.add "Resource", valid_602378
  var valid_602392 = query.getOrDefault("Operation")
  valid_602392 = validateParameter(valid_602392, JString, required = true,
                                 default = newJString("Tag"))
  if valid_602392 != nil:
    section.add "Operation", valid_602392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602393 = header.getOrDefault("X-Amz-Signature")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Signature", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Content-Sha256", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Date")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Date", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Credential")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Credential", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Security-Token")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Security-Token", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Algorithm")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Algorithm", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-SignedHeaders", valid_602399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602401: Call_TagResource20170325_602375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Add tags to a CloudFront resource.
  ## 
  let valid = call_602401.validator(path, query, header, formData, body)
  let scheme = call_602401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602401.url(scheme.get, call_602401.host, call_602401.base,
                         call_602401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602401, url, valid)

proc call*(call_602402: Call_TagResource20170325_602375; Resource: string;
          body: JsonNode; Operation: string = "Tag"): Recallable =
  ## tagResource20170325
  ## Add tags to a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_602403 = newJObject()
  var body_602404 = newJObject()
  add(query_602403, "Resource", newJString(Resource))
  add(query_602403, "Operation", newJString(Operation))
  if body != nil:
    body_602404 = body
  result = call_602402.call(nil, query_602403, nil, nil, body_602404)

var tagResource20170325* = Call_TagResource20170325_602375(
    name: "tagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Tag&Resource",
    validator: validate_TagResource20170325_602376, base: "/",
    url: url_TagResource20170325_602377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource20170325_602405 = ref object of OpenApiRestCall_601389
proc url_UntagResource20170325_602407(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource20170325_602406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove tags from a CloudFront resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Resource: JString (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Resource` field"
  var valid_602408 = query.getOrDefault("Resource")
  valid_602408 = validateParameter(valid_602408, JString, required = true,
                                 default = nil)
  if valid_602408 != nil:
    section.add "Resource", valid_602408
  var valid_602409 = query.getOrDefault("Operation")
  valid_602409 = validateParameter(valid_602409, JString, required = true,
                                 default = newJString("Untag"))
  if valid_602409 != nil:
    section.add "Operation", valid_602409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602410 = header.getOrDefault("X-Amz-Signature")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Signature", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Content-Sha256", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Date")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Date", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Credential")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Credential", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Security-Token")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Security-Token", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Algorithm")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Algorithm", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-SignedHeaders", valid_602416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602418: Call_UntagResource20170325_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove tags from a CloudFront resource.
  ## 
  let valid = call_602418.validator(path, query, header, formData, body)
  let scheme = call_602418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602418.url(scheme.get, call_602418.host, call_602418.base,
                         call_602418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602418, url, valid)

proc call*(call_602419: Call_UntagResource20170325_602405; Resource: string;
          body: JsonNode; Operation: string = "Untag"): Recallable =
  ## untagResource20170325
  ## Remove tags from a CloudFront resource.
  ##   Resource: string (required)
  ##           :  An ARN of a CloudFront resource.
  ##   Operation: string (required)
  ##   body: JObject (required)
  var query_602420 = newJObject()
  var body_602421 = newJObject()
  add(query_602420, "Resource", newJString(Resource))
  add(query_602420, "Operation", newJString(Operation))
  if body != nil:
    body_602421 = body
  result = call_602419.call(nil, query_602420, nil, nil, body_602421)

var untagResource20170325* = Call_UntagResource20170325_602405(
    name: "untagResource20170325", meth: HttpMethod.HttpPost,
    host: "cloudfront.amazonaws.com",
    route: "/2017-03-25/tagging#Operation=Untag&Resource",
    validator: validate_UntagResource20170325_602406, base: "/",
    url: url_UntagResource20170325_602407, schemes: {Scheme.Https, Scheme.Http})
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
